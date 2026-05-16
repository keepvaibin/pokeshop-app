import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/json_helpers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pk_button.dart';
import '../../../../core/widgets/pk_card.dart';
import '../../../../core/widgets/pk_status_badge.dart';
import '../../../../core/widgets/pokemon_avatar.dart';
import '../../data/admin_repository.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _searchController = TextEditingController();
  String _search = '';
  int _page = 1;
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        actions: [
          IconButton(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh')
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && !snapshot.hasData) {
            return Center(child: Text('${snapshot.error}'));
          }
          final data = snapshot.data ?? const <String, dynamic>{};
          final users = asMapList(data['results']);
          final totalPages = asInt(data['total_pages'], fallback: 1);
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: users.length + 2,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Customer accounts',
                          style: AppTextStyles.heading(size: 24)),
                      const SizedBox(height: 12),
                      PkCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.search),
                                    labelText: 'Search users'),
                                textInputAction: TextInputAction.search,
                                onSubmitted: (value) {
                                  setState(() {
                                    _search = value;
                                    _page = 1;
                                  });
                                  _refresh();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              onPressed: () {
                                setState(() {
                                  _search = _searchController.text;
                                  _page = 1;
                                });
                                _refresh();
                              },
                              icon: const Icon(Icons.arrow_forward),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                if (index == 1) {
                  return _Pager(
                      page: _page,
                      totalPages: totalPages,
                      onPrev: _page > 1 ? () => _setPage(_page - 1) : null,
                      onNext: _page < totalPages
                          ? () => _setPage(_page + 1)
                          : null);
                }
                return _UserCard(
                    user: users[index - 2],
                    onTap: () => _openDetail(users[index - 2]));
              },
            ),
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _load() {
    return ref
        .read(adminRepositoryProvider)
        .loadUsers(search: _search, page: _page);
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  void _setPage(int page) {
    setState(() {
      _page = page;
      _future = _load();
    });
  }

  void _openDetail(Map<String, dynamic> user) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _UserDetailSheet(userId: asInt(user['id'])),
    ).whenComplete(_refresh);
  }
}

class _Pager extends StatelessWidget {
  const _Pager(
      {required this.page, required this.totalPages, this.onPrev, this.onNext});

  final int page;
  final int totalPages;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
            onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
        Expanded(child: Center(child: Text('Page $page of $totalPages'))),
        IconButton.filledTonal(
            onPressed: onNext, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.onTap});

  final Map<String, dynamic> user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: PkCard(
        child: Row(
          children: [
            PokemonAvatar(
              filename: asString(user['pokemon_icon_filename']),
              fallbackText: asString(user['display_name'],
                  fallback: asString(user['email'])),
              size: 48,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      asString(user['display_name'],
                          fallback: asString(user['email'])),
                      style: AppTextStyles.heading(size: 16)),
                  const SizedBox(height: 2),
                  Text(asString(user['email']),
                      style: AppTextStyles.body(
                          size: 12, color: AppColors.pkmnGrayDark)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _TinyStat(
                          label: 'Credit',
                          value:
                              '\$${asDouble(user['trade_credit_balance']).toStringAsFixed(2)}'),
                      _TinyStat(
                          label: 'Strikes',
                          value: '${asInt(user['strike_count'])}',
                          valueColor: asInt(user['strike_count']) > 0
                              ? AppColors.pkmnRed
                              : null),
                      _TinyStat(
                          label: 'Active',
                          value: '${asInt(user['current_order_count'])}'),
                      if (asBool(user['is_admin']))
                        _TinyStat(
                            label: 'Admin',
                            value: '',
                            backgroundColor:
                                AppColors.pkmnBlue.withValues(alpha: 0.15),
                            valueColor: AppColors.pkmnBlue),
                      if (asBool(user['is_restricted']))
                        _TinyStat(
                            label: 'Restricted',
                            value: '',
                            backgroundColor:
                                AppColors.pkmnRed.withValues(alpha: 0.15),
                            valueColor: AppColors.pkmnRed),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _TinyStat extends StatelessWidget {
  const _TinyStat(
      {required this.label,
      required this.value,
      this.valueColor,
      this.backgroundColor});

  final String label;
  final String value;
  final Color? valueColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final display =
        (label.isNotEmpty && value.isNotEmpty) ? '$label $value' : label + value;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.pkmnGrayLight,
          borderRadius: BorderRadius.circular(8)),
      child: Text(display,
          style: AppTextStyles.body(
              size: 11,
              color: valueColor ?? AppColors.pkmnGray)),
    );
  }
}

class _UserDetailSheet extends ConsumerStatefulWidget {
  const _UserDetailSheet({required this.userId});

  final int userId;

  @override
  ConsumerState<_UserDetailSheet> createState() => _UserDetailSheetState();
}

class _UserDetailSheetState extends ConsumerState<_UserDetailSheet> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.88),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError && !snapshot.hasData) {
              return Center(child: Text('${snapshot.error}'));
            }
            final data = snapshot.data ?? const <String, dynamic>{};
            final user = asMap(data['user']);
            final currentOrders = asMapList(data['current_orders']);
            final recentOrders = asMapList(data['recent_orders']);
            final strikes = asMapList(data['strikes']);
            final ledger = asMapList(data['recent_credit_ledger']);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Row(
                  children: [
                    PokemonAvatar(
                      filename: asString(user['pokemon_icon_filename']),
                      fallbackText: asString(user['display_name'],
                          fallback: asString(user['email'])),
                      size: 60,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              asString(user['display_name'],
                                  fallback: asString(user['email'])),
                              style: AppTextStyles.heading(size: 20)),
                          Text(asString(user['email']),
                              style: AppTextStyles.body(size: 13)),
                          if (asString(user['date_joined']).isNotEmpty)
                            Text(
                                'Joined: ${_fmtDate(asString(user['date_joined']))}',
                                style: AppTextStyles.body(
                                    size: 11,
                                    color: AppColors.pkmnGrayDark)),
                          if (asString(user['last_login']).isNotEmpty)
                            Text(
                                'Last login: ${_fmtDate(asString(user['last_login']))}',
                                style: AppTextStyles.body(
                                    size: 11,
                                    color: AppColors.pkmnGrayDark)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TinyStat(
                        label: 'Wallet',
                        value:
                            '\$${asDouble(user['trade_credit_balance']).toStringAsFixed(2)}'),
                    _TinyStat(
                        label: 'Strikes',
                        value: '${asInt(user['strike_count'])}'),
                    _TinyStat(
                        label: 'Orders',
                        value: '${asInt(user['recent_order_count'])}'),
                    if (asBool(user['is_admin']))
                      const _TinyStat(label: 'Role', value: 'Admin'),
                    if (asBool(user['is_restricted']))
                      const _TinyStat(label: 'Restricted', value: 'Yes'),
                  ],
                ),
                const SizedBox(height: 12),
                PkButton(
                    label: 'Grant Store Credit',
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                    onPressed: _grantCredit,
                    expand: true),
                const SizedBox(height: 8),
                PkButton(
                    label: 'Issue Strike',
                    icon: const Icon(Icons.report_gmailerrorred_outlined),
                    variant: PkButtonVariant.destructive,
                    onPressed: () => _issueStrike(asInt(user['id'])),
                    expand: true),
                const SizedBox(height: 16),
                _OrdersSection(title: 'Current Orders', orders: currentOrders),
                const SizedBox(height: 12),
                _OrdersSection(title: 'Recent Orders', orders: recentOrders),
                const SizedBox(height: 12),
                _SimpleRows(
                    title: 'Strikes',
                    rows: strikes,
                    titleBuilder: (row) => asString(row['reason']),
                    subtitleBuilder: (row) => asString(row['created_at'])),
                const SizedBox(height: 12),
                _SimpleRows(
                    title: 'Credit Ledger',
                    rows: ledger,
                    titleBuilder: (row) =>
                        '${asString(row['transaction_type']).replaceAll('_', ' ')} • \$${asDouble(row['amount']).toStringAsFixed(2)}',
                    subtitleBuilder: (row) => asString(row['note'])),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _load() {
    return ref.read(adminRepositoryProvider).loadUserDetail(widget.userId);
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  static String _fmtDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return DateFormat('MMM d, y').format(parsed.toLocal());
  }

  Future<void> _issueStrike(int userId) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Issue Strike'),
        content: TextField(
          controller: reasonController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Reason'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.pkmnRed),
            onPressed: () {
              final text = reasonController.text.trim();
              if (text.isEmpty) return;
              Navigator.of(context).pop(text);
            },
            child: const Text('Issue'),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (reason == null || !mounted) return;
    try {
      await ref
          .read(adminRepositoryProvider)
          .issueStrike(userId: userId, reason: reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Strike issued.')));
      _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _grantCredit() async {
    final result = await showDialog<({String amount, String note})>(
      context: context,
      builder: (context) => const _GrantCreditDialog(),
    );
    if (result == null) return;
    try {
      await ref.read(adminRepositoryProvider).grantCredit(
          userId: widget.userId, amount: result.amount, note: result.note);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Credit granted.')));
      _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}

class _OrdersSection extends StatelessWidget {
  const _OrdersSection({required this.title, required this.orders});

  final String title;
  final List<Map<String, dynamic>> orders;

  @override
  Widget build(BuildContext context) {
    return PkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.heading(size: 18)),
          const SizedBox(height: 8),
          if (orders.isEmpty)
            const Text('None.')
          else
            ...orders.map((order) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(asString(order['items_summary'],
                      fallback: asString(order['order_id']))),
                  subtitle: Text(
                      '\$${asDouble(order['total']).toStringAsFixed(2)} • ${asString(order['pickup_label'])}'),
                  trailing: PkStatusBadge(status: asString(order['status'])),
                  onTap: () => context
                      .push('/admin/orders/${asString(order['order_id'])}'),
                )),
        ],
      ),
    );
  }
}

class _SimpleRows extends StatelessWidget {
  const _SimpleRows(
      {required this.title,
      required this.rows,
      required this.titleBuilder,
      required this.subtitleBuilder});

  final String title;
  final List<Map<String, dynamic>> rows;
  final String Function(Map<String, dynamic> row) titleBuilder;
  final String Function(Map<String, dynamic> row) subtitleBuilder;

  @override
  Widget build(BuildContext context) {
    return PkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.heading(size: 18)),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            const Text('None.')
          else
            ...rows.map((row) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(titleBuilder(row)),
                  subtitle: Text(subtitleBuilder(row)),
                )),
        ],
      ),
    );
  }
}

class _GrantCreditDialog extends StatefulWidget {
  const _GrantCreditDialog();

  @override
  State<_GrantCreditDialog> createState() => _GrantCreditDialogState();
}

class _GrantCreditDialogState extends State<_GrantCreditDialog> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Grant Store Credit'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _noteController,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Note'),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final amount = _amountController.text.trim();
            if ((double.tryParse(amount) ?? 0) <= 0) return;
            Navigator.of(context)
                .pop((amount: amount, note: _noteController.text.trim()));
          },
          child: const Text('Grant'),
        ),
      ],
    );
  }
}
