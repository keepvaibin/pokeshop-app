import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/api_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pk_card.dart';
import '../../../../core/widgets/pk_input.dart';
import '../../../../core/widgets/pk_status_badge.dart';
import '../../data/orders_repository.dart';

const _kCancellableStatuses = {
  'pending',
  'cash_needed',
  'trade_review',
  'pending_counteroffer',
};

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _status = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(adminOrdersProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Orders'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(adminOrdersProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: orders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('$error')),
        data: (items) {
          final filtered = items.where(_matchesFilters).toList();
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminOrdersProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Order History', style: AppTextStyles.heading(size: 24)),
                const SizedBox(height: 4),
                Text('All orders across all statuses.',
                    style: AppTextStyles.body()),
                const SizedBox(height: 16),
                PkCard(
                  child: Column(
                    children: [
                      PkInput(
                        controller: _searchController,
                        label: 'Search orders, customers, items',
                        textInputAction: TextInputAction.search,
                        onChanged: (value) => setState(() => _query = value),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: DropdownButtonFormField<String>(
                          initialValue: _status,
                          decoration:
                              const InputDecoration(labelText: 'Status'),
                          items: const [
                            DropdownMenuItem(
                                value: '', child: Text('All statuses')),
                            DropdownMenuItem(
                                value: 'active', child: Text('Current orders')),
                            DropdownMenuItem(
                                value: 'pending', child: Text('Pending')),
                            DropdownMenuItem(
                                value: 'trade_review',
                                child: Text('Trade review')),
                            DropdownMenuItem(
                                value: 'pending_counteroffer',
                                child: Text('Counteroffer')),
                            DropdownMenuItem(
                                value: 'cash_needed',
                                child: Text('Balance due')),
                            DropdownMenuItem(
                                value: 'fulfilled', child: Text('Fulfilled')),
                            DropdownMenuItem(
                                value: 'cancelled', child: Text('Cancelled')),
                          ],
                          onChanged: (value) =>
                              setState(() => _status = value ?? ''),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  const PkCard(child: Text('No orders found.'))
                else
                  ...filtered.map((order) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AdminOrderCard(
                            order: order, onCancel: () => _cancelOrder(order)),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _matchesFilters(OrderSummary order) {
    if (_status == 'active' && !_activeStatuses.contains(order.status)) {
      return false;
    }
    if (_status.isNotEmpty && _status != 'active' && order.status != _status) {
      return false;
    }
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }
    return [
      order.orderId,
      order.customerEmail,
      order.discordHandle,
      order.itemsSummary,
      order.couponCode,
      ...order.items.map((line) => line.title),
    ].any((value) => value.toLowerCase().contains(query));
  }

  static const _activeStatuses = _kCancellableStatuses;

  Future<void> _cancelOrder(OrderSummary order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel order?'),
        content:
            Text('Cancel order ${order.orderId}? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Back')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.pkmnRed),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(ordersRepositoryProvider)
          .adminCancelOrder(orderId: order.orderId, reason: 'Cancelled by admin');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order cancelled.')));
      ref.invalidate(adminOrdersProvider);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $error')));
    }
  }
}

class _AdminOrderCard extends StatelessWidget {
  const _AdminOrderCard({required this.order, required this.onCancel});

  final OrderSummary order;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final date = _formatDate(order.createdAt);
    final customer = [order.customerEmail, order.discordHandle]
        .where((value) => value.trim().isNotEmpty)
        .join(' • ');
    final itemText = order.itemsSummary.isNotEmpty
        ? order.itemsSummary
        : order.items
            .map((line) => '${line.title} x${line.quantity}')
            .join(', ');
    final isCancellable = _kCancellableStatuses.contains(order.status);
    return InkWell(
      onTap: () => context.push('/admin/orders/${order.orderId}'),
      child: PkCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.orderId,
                          style: AppTextStyles.heading(size: 16)),
                      if (date.isNotEmpty)
                        Text(date,
                            style: AppTextStyles.body(
                                size: 12, color: AppColors.pkmnGrayDark)),
                    ],
                  ),
                ),
                PkStatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 10),
            if (customer.isNotEmpty)
              Text(customer, style: AppTextStyles.body(size: 13)),
            if (customer.isNotEmpty) const SizedBox(height: 6),
            Text(itemText.isEmpty ? 'No item summary' : itemText,
                maxLines: 3, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _Meta(
                    label: 'Due',
                    value: '\$${order.netDue.toStringAsFixed(2)}'),
                _Meta(
                    label: 'Payment',
                    value: order.paymentMethod.replaceAll('_', ' ')),
                _Meta(
                    label: 'Pickup',
                    value: order.pickupLabel.isEmpty
                        ? order.deliveryMethod
                        : order.pickupLabel),
              ],
            ),
            if (isCancellable) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.pkmnRed),
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text('Cancel Order'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return '';
    return DateFormat('MMM d, y h:mm a').format(parsed.toLocal());
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label.toUpperCase(),
            style: AppTextStyles.label(color: AppColors.pkmnGrayDark)
                .copyWith(fontSize: 10)),
        const SizedBox(height: 2),
        Text(value.isEmpty ? '-' : value, style: AppTextStyles.body(size: 13)),
      ],
    );
  }
}
