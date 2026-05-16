import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/api_models.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/json_helpers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pk_button.dart';
import '../../../../core/widgets/pk_card.dart';
import '../../../checkout/presentation/widgets/timeslot_selector.dart';
import '../../data/admin_repository.dart';

class AdminPosScreen extends ConsumerStatefulWidget {
  const AdminPosScreen({super.key});

  @override
  ConsumerState<AdminPosScreen> createState() => _AdminPosScreenState();
}

class _AdminPosScreenState extends ConsumerState<AdminPosScreen> {
  final _userSearchController = TextEditingController();
  final _itemSearchController = TextEditingController();
  final _discordController = TextEditingController();
  final _notesController = TextEditingController();

  List<Map<String, dynamic>> _userResults = const [];
  Map<String, dynamic>? _selectedUser;
  List<ProductItem> _inventory = const [];
  final List<_PosCartLine> _cart = [];
  String _itemQuery = '';
  String _paymentMethod = 'cash';
  String _deliveryMethod = 'asap';
  TimeslotSelection? _timeslot;
  bool _loadingInventory = true;
  bool _searchingUsers = false;
  bool _submitting = false;
  String? _error;

  double get _subtotal => _cart.fold(0, (sum, line) => sum + line.subtotal);

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  @override
  void dispose() {
    _userSearchController.dispose();
    _itemSearchController.dispose();
    _discordController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _visibleItems();
    return Scaffold(
      appBar: AppBar(title: const Text('Point of Sale')),
      body: RefreshIndicator(
        onRefresh: _loadInventory,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Create in-person order',
                style: AppTextStyles.heading(size: 24)),
            const SizedBox(height: 12),
            _CustomerPanel(
              controller: _userSearchController,
              searching: _searchingUsers,
              selectedUser: _selectedUser,
              results: _userResults,
              onSearch: _searchUsers,
              onSelect: (user) => setState(() {
                _selectedUser = user;
                _userResults = const [];
                _userSearchController.text = asString(user['email']);
                _discordController.text = asString(user['discord_handle']);
              }),
              onClear: () => setState(() {
                _selectedUser = null;
                _userResults = const [];
                _userSearchController.clear();
                _discordController.clear();
              }),
            ),
            const SizedBox(height: 12),
            PkCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Items', style: AppTextStyles.heading(size: 18)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _itemSearchController,
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        labelText: 'Search inventory'),
                    onChanged: (value) => setState(() => _itemQuery = value),
                  ),
                  const SizedBox(height: 10),
                  if (_loadingInventory)
                    const Center(child: CircularProgressIndicator())
                  else if (visibleItems.isEmpty)
                    const Text('No matching active inventory.')
                  else
                    ...visibleItems.take(8).map((item) =>
                        _InventoryRow(item: item, onAdd: () => _addItem(item))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _CartPanel(
              lines: _cart,
              subtotal: _subtotal,
              onIncrement: (line) => setState(() => line.quantity += 1),
              onDecrement: (line) => setState(() {
                line.quantity -= 1;
                if (line.quantity <= 0) _cart.remove(line);
              }),
            ),
            const SizedBox(height: 12),
            PkCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment + Pickup',
                      style: AppTextStyles.heading(size: 18)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _paymentMethod,
                    decoration:
                        const InputDecoration(labelText: 'Payment Method'),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'venmo', child: Text('Venmo')),
                      DropdownMenuItem(value: 'zelle', child: Text('Zelle')),
                      DropdownMenuItem(value: 'paypal', child: Text('PayPal')),
                    ],
                    onChanged: (value) =>
                        setState(() => _paymentMethod = value ?? 'cash'),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'asap', label: Text('ASAP')),
                      ButtonSegment(
                          value: 'scheduled', label: Text('Scheduled')),
                    ],
                    selected: {_deliveryMethod},
                    onSelectionChanged: (value) =>
                        setState(() => _deliveryMethod = value.first),
                  ),
                  if (_deliveryMethod == 'scheduled') ...[
                    const SizedBox(height: 12),
                    TimeslotSelector(
                        value: _timeslot,
                        onChanged: (value) =>
                            setState(() => _timeslot = value)),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _discordController,
                    decoration:
                        const InputDecoration(labelText: 'Discord Handle'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Admin Notes'),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: AppTextStyles.body(color: AppColors.pkmnRed)),
            ],
            const SizedBox(height: 16),
            PkButton(
              label: 'Create Order',
              icon: const Icon(Icons.point_of_sale_outlined),
              loading: _submitting,
              expand: true,
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadInventory() async {
    setState(() => _loadingInventory = true);
    try {
      final items = await ref
          .read(adminRepositoryProvider)
          .listResource(ApiEndpoints.adminPosInventory);
      if (!mounted) return;
      setState(() {
        _inventory = items.map(ProductItem.fromJson).toList();
        _loadingInventory = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _loadingInventory = false;
      });
    }
  }

  Future<void> _searchUsers(String value) async {
    final query = value.trim();
    if (query.length < 2) {
      setState(() => _userResults = const []);
      return;
    }
    setState(() => _searchingUsers = true);
    try {
      final results =
          await ref.read(adminRepositoryProvider).searchPosUsers(query);
      if (!mounted) return;
      setState(() => _userResults = results);
    } catch (_) {
      if (!mounted) return;
      setState(() => _userResults = const []);
    } finally {
      if (mounted) setState(() => _searchingUsers = false);
    }
  }

  List<ProductItem> _visibleItems() {
    final query = _itemQuery.trim().toLowerCase();
    final source = query.isEmpty
        ? _inventory
        : _inventory.where((item) {
            return [
              item.title,
              item.category,
              item.subcategory,
              item.setName,
              item.rarity
            ].any((value) => value.toLowerCase().contains(query));
          }).toList(growable: false);
    return source
        .where((item) => item.stockQuantity > 0)
        .toList(growable: false);
  }

  void _addItem(ProductItem item) {
    final existing = _cart.where((line) => line.item.id == item.id).toList();
    setState(() {
      if (existing.isEmpty) {
        _cart.add(_PosCartLine(item: item));
      } else {
        existing.first.quantity += 1;
      }
    });
  }

  Future<void> _submit() async {
    if (_selectedUser == null || _cart.isEmpty) {
      setState(() => _error = 'Select a customer and add at least one item.');
      return;
    }
    if (_deliveryMethod == 'scheduled' && _timeslot == null) {
      setState(() => _error = 'Choose a scheduled pickup time.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final payload = {
        'target_user_id': asInt(_selectedUser!['id']),
        'items': [
          for (final line in _cart)
            {'item_id': line.item.id, 'quantity': line.quantity}
        ],
        'payment_method': _paymentMethod,
        'delivery_method': _deliveryMethod,
        'recurring_timeslot_id': _deliveryMethod == 'scheduled'
            ? _timeslot?.recurringTimeslotId
            : null,
        'pickup_date':
            _deliveryMethod == 'scheduled' ? _timeslot?.pickupDate : null,
        'discord_handle': _discordController.text.trim(),
        'admin_notes': _notesController.text.trim(),
      };
      final order =
          await ref.read(adminRepositoryProvider).createPosOrder(payload);
      if (!mounted) return;
      final orderId =
          asString(order['order_id'], fallback: asString(order['id']));
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Order created.')));
      setState(() {
        _cart.clear();
        _notesController.clear();
        _submitting = false;
      });
      if (orderId.isNotEmpty) await context.push('/admin/orders/$orderId');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _submitting = false;
      });
    }
  }
}

class _CustomerPanel extends StatelessWidget {
  const _CustomerPanel({
    required this.controller,
    required this.searching,
    required this.selectedUser,
    required this.results,
    required this.onSearch,
    required this.onSelect,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool searching;
  final Map<String, dynamic>? selectedUser;
  final List<Map<String, dynamic>> results;
  final ValueChanged<String> onSearch;
  final ValueChanged<Map<String, dynamic>> onSelect;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return PkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Customer', style: AppTextStyles.heading(size: 18)),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.person_search_outlined),
              suffixIcon: searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : null,
              labelText: 'Search by email, name, Discord',
            ),
            onChanged: onSearch,
          ),
          if (selectedUser != null) ...[
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading:
                  const Icon(Icons.check_circle, color: AppColors.pkmnBlue),
              title: Text(asString(selectedUser!['email'])),
              subtitle: Text([
                asString(selectedUser!['nickname']),
                asString(selectedUser!['discord_handle'])
              ].where((value) => value.isNotEmpty).join(' • ')),
              trailing:
                  IconButton(onPressed: onClear, icon: const Icon(Icons.close)),
            ),
          ] else if (results.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...results.map((user) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline),
                  title: Text(asString(user['email'])),
                  subtitle: Text([
                    asString(user['nickname']),
                    asString(user['discord_handle'])
                  ].where((value) => value.isNotEmpty).join(' • ')),
                  onTap: () => onSelect(user),
                )),
          ],
        ],
      ),
    );
  }
}

class _InventoryRow extends StatelessWidget {
  const _InventoryRow({required this.item, required this.onAdd});

  final ProductItem item;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
          '\$${item.price.toStringAsFixed(2)} • ${item.stockQuantity} in stock'),
      trailing: IconButton.filledTonal(
          onPressed: onAdd, icon: const Icon(Icons.add_shopping_cart)),
    );
  }
}

class _CartPanel extends StatelessWidget {
  const _CartPanel(
      {required this.lines,
      required this.subtotal,
      required this.onIncrement,
      required this.onDecrement});

  final List<_PosCartLine> lines;
  final double subtotal;
  final ValueChanged<_PosCartLine> onIncrement;
  final ValueChanged<_PosCartLine> onDecrement;

  @override
  Widget build(BuildContext context) {
    return PkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text('Cart', style: AppTextStyles.heading(size: 18))),
              Text('\$${subtotal.toStringAsFixed(2)}',
                  style: AppTextStyles.heading(
                      size: 18, color: AppColors.pkmnBlue)),
            ],
          ),
          const SizedBox(height: 8),
          if (lines.isEmpty)
            const Text('No items added.')
          else
            ...lines.map((line) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(line.item.title,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle:
                      Text('\$${line.item.price.toStringAsFixed(2)} each'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          onPressed: () => onDecrement(line),
                          icon: const Icon(Icons.remove_circle_outline)),
                      Text('${line.quantity}',
                          style: AppTextStyles.heading(size: 16)),
                      IconButton(
                          onPressed: () => onIncrement(line),
                          icon: const Icon(Icons.add_circle_outline)),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

class _PosCartLine {
  _PosCartLine({required this.item});

  final ProductItem item;
  int quantity = 1;

  double get subtotal => item.price * quantity;
}
