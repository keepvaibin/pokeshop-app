import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/api_models.dart';
import '../../../../core/network/json_helpers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pk_button.dart';
import '../../../../core/widgets/pk_card.dart';
import '../../../../core/widgets/pk_status_badge.dart';
import '../../data/admin_repository.dart';

class AdminDispatchScreen extends ConsumerWidget {
  const AdminDispatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundle = ref.watch(adminDispatchCenterProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispatch'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(adminDispatchCenterProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: bundle.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _DispatchError(
          message: '$error',
          onRetry: () => ref.invalidate(adminDispatchCenterProvider),
        ),
        data: (data) {
          final fulfillmentOrders = [
            ...data.urgentAsapOrders,
            ...data.fulfillmentOrders.where(
              (order) => !data.urgentAsapOrders.contains(order),
            ),
          ];
          final tradeOrders = data.tradeOrders;
          final tradeIns = data.activeTradeIns;
          final overdueOrders = data.overdueOrders;
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminDispatchCenterProvider),
            child: DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  _DispatchSummary(bundle: data),
                  TabBar(
                    isScrollable: false,
                    labelPadding: EdgeInsets.zero,
                    tabs: [
                      Tab(
                          child: _DispatchTabLabel(
                              label: 'Fulfillment',
                              count: fulfillmentOrders.length)),
                      Tab(
                          child: _DispatchTabLabel(
                              label: 'Trade Desk', count: tradeOrders.length)),
                      Tab(
                          child: _DispatchTabLabel(
                              label: 'Trades', count: tradeIns.length)),
                      Tab(
                          child: _DispatchTabLabel(
                              label: 'Overdue', count: overdueOrders.length)),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _OrderList(
                          emptyLabel: 'No fulfillment orders right now.',
                          orders: fulfillmentOrders,
                          showAsapWarning: true,
                        ),
                        _OrderList(
                          emptyLabel: 'No trade orders awaiting review.',
                          orders: tradeOrders,
                        ),
                        _TradeInList(tradeIns: tradeIns),
                        _OrderList(
                          emptyLabel: 'No overdue orders.',
                          orders: overdueOrders,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DispatchTabLabel extends StatelessWidget {
  const _DispatchTabLabel({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Text('$label ($count)', maxLines: 1),
      ),
    );
  }
}

class _DispatchSummary extends StatelessWidget {
  const _DispatchSummary({required this.bundle});

  final AdminDispatchBundle bundle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: _MetricTile(
              label: 'ASAP',
              value: '${bundle.urgentAsapOrders.length}',
              color: AppColors.pkmnRed,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MetricTile(
              label: 'Fulfill',
              value: '${bundle.fulfillmentOrders.length}',
              color: AppColors.pkmnBlue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MetricTile(
              label: 'Trades',
              value:
                  '${bundle.tradeOrders.length + bundle.activeTradeIns.length}',
              color: AppColors.pkmnYellowDark,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MetricTile(
              label: 'Late',
              value: '${bundle.overdueOrders.length}',
              color: AppColors.pkmnGray,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile(
      {required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return PkCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.heading(size: 18, color: color)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.label(color: AppColors.pkmnGray)),
        ],
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({
    required this.emptyLabel,
    required this.orders,
    this.showAsapWarning = false,
  });

  final String emptyLabel;
  final List<OrderSummary> orders;
  final bool showAsapWarning;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PkCard(child: Text(emptyLabel, style: AppTextStyles.body()))
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _DispatchOrderCard(
        order: orders[index],
        showAsapWarning: showAsapWarning,
      ),
    );
  }
}

class _DispatchOrderCard extends ConsumerWidget {
  const _DispatchOrderCard(
      {required this.order, required this.showAsapWarning});

  final OrderSummary order;
  final bool showAsapWarning;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUrgentAsap =
        order.deliveryMethod == 'asap' && !order.isAcknowledged;
    return PkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child:
                    Text(order.orderId, style: AppTextStyles.heading(size: 16)),
              ),
              PkStatusBadge(status: order.status),
            ],
          ),
          if (showAsapWarning && isUrgentAsap) ...[
            const SizedBox(height: 8),
            Text(
              'ASAP needs pickup scheduling',
              style: AppTextStyles.label(color: AppColors.pkmnRed),
            ),
          ],
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.person_outline, text: _customerLabel(order)),
          _InfoRow(icon: Icons.schedule_outlined, text: _pickupLabel(order)),
          _InfoRow(icon: Icons.payments_outlined, text: _paymentLabel(order)),
          const SizedBox(height: 8),
          Text(
            _itemsLabel(order),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body(color: AppColors.pkmnText),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PkButton(
                label: 'Receipt',
                icon: const Icon(Icons.receipt_long_outlined),
                variant: PkButtonVariant.secondary,
                onPressed: () => context.push('/admin/orders/${order.orderId}'),
              ),
              PkButton(
                label: 'Actions',
                icon: const Icon(Icons.more_horiz),
                variant: PkButtonVariant.secondary,
                onPressed: () => _showActionSheet(context, ref, order),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _customerLabel(OrderSummary order) {
    if (order.customerEmail.isNotEmpty) return order.customerEmail;
    if (order.discordHandle.isNotEmpty) return order.discordHandle;
    return 'Customer not attached';
  }

  String _pickupLabel(OrderSummary order) {
    if (order.pickupLabel.isNotEmpty) return order.pickupLabel;
    if (order.pickupDate.isNotEmpty) return order.pickupDate;
    return order.deliveryMethod.isEmpty
        ? 'Pickup not scheduled'
        : order.deliveryMethod;
  }

  String _paymentLabel(OrderSummary order) {
    final method = order.paymentMethod.replaceAll('_', ' ');
    return '${method.isEmpty ? 'Payment' : method} - due \$${order.netDue.toStringAsFixed(2)}';
  }

  String _itemsLabel(OrderSummary order) {
    if (order.itemsSummary.isNotEmpty) return order.itemsSummary;
    if (order.items.isEmpty) return 'No item summary returned';
    return order.items
        .map((line) => '${line.title} x${line.quantity}')
        .join(', ');
  }

  void _showActionSheet(
      BuildContext parentContext, WidgetRef ref, OrderSummary order) {
    showModalBottomSheet<void>(
      context: parentContext,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Dispatch actions', style: AppTextStyles.heading(size: 20)),
              const SizedBox(height: 8),
              Text(order.orderId, style: AppTextStyles.body()),
              const SizedBox(height: 16),
              PkButton(
                label: 'View Receipt',
                onPressed: () {
                  Navigator.of(context).pop();
                  parentContext.push('/admin/orders/${order.orderId}');
                },
                expand: true,
              ),
              if (order.discordHandle.isNotEmpty) ...[
                const SizedBox(height: 10),
                PkButton(
                  label: 'Copy Discord',
                  variant: PkButtonVariant.secondary,
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await Clipboard.setData(
                        ClipboardData(text: order.discordHandle));
                    if (parentContext.mounted) {
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        const SnackBar(content: Text('Discord handle copied')),
                      );
                    }
                  },
                  expand: true,
                ),
              ],
              if (order.status == 'pending' ||
                  order.status == 'cash_needed') ...[
                if (order.deliveryMethod == 'asap' &&
                    !order.isAcknowledged) ...[
                  const SizedBox(height: 10),
                  PkButton(
                    label: 'Schedule ASAP Pickup',
                    icon: const Icon(Icons.event_available_outlined),
                    variant: PkButtonVariant.accent,
                    onPressed: () {
                      Navigator.of(context).pop();
                      _scheduleAsap(parentContext, ref, order);
                    },
                    expand: true,
                  ),
                ],
                const SizedBox(height: 10),
                PkButton(
                  label: 'Mark Fulfilled',
                  onPressed: () => _runAction(
                    parentContext,
                    context,
                    ref,
                    order,
                    'fulfill',
                    successMessage: 'Order marked fulfilled',
                  ),
                  expand: true,
                ),
              ],
              if (order.status == 'trade_review') ...[
                const SizedBox(height: 10),
                PkButton(
                  label: 'Approve Trade',
                  onPressed: () => _runAction(
                    parentContext,
                    context,
                    ref,
                    order,
                    'approve_trade',
                    successMessage: 'Trade approved',
                  ),
                  expand: true,
                ),
                const SizedBox(height: 10),
                PkButton(
                  label: 'Deny Trade',
                  variant: PkButtonVariant.destructive,
                  onPressed: () => _runAction(
                    parentContext,
                    context,
                    ref,
                    order,
                    'deny_trade',
                    successMessage: 'Trade denied',
                  ),
                  expand: true,
                ),
              ],
              if (order.status != 'cancelled' &&
                  order.status != 'fulfilled') ...[
                const SizedBox(height: 10),
                PkButton(
                  label: 'Cancel Order',
                  variant: PkButtonVariant.destructive,
                  onPressed: () => _confirmCancel(
                    parentContext,
                    context,
                    ref,
                    order,
                  ),
                  expand: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _runAction(
    BuildContext parentContext,
    BuildContext sheetContext,
    WidgetRef ref,
    OrderSummary order,
    String action, {
    Map<String, dynamic> extra = const {},
    required String successMessage,
  }) async {
    Navigator.of(sheetContext).pop();
    try {
      await ref.read(adminRepositoryProvider).runDispatchAction(
            orderId: order.id,
            action: action,
            extra: extra,
          );
      ref.invalidate(adminDispatchCenterProvider);
      if (parentContext.mounted) {
        ScaffoldMessenger.of(parentContext)
            .showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } catch (error) {
      if (parentContext.mounted) {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          SnackBar(content: Text('Dispatch action failed: $error')),
        );
      }
    }
  }

  Future<void> _confirmCancel(
    BuildContext parentContext,
    BuildContext sheetContext,
    WidgetRef ref,
    OrderSummary order,
  ) async {
    final shouldCancel = await showDialog<bool>(
      context: sheetContext,
      builder: (context) => AlertDialog(
        title: const Text('Cancel order?'),
        content: Text('This will cancel ${order.orderId} from dispatch.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Order'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
    if (shouldCancel != true ||
        !parentContext.mounted ||
        !sheetContext.mounted) {
      return;
    }
    await _runAction(
      parentContext,
      sheetContext,
      ref,
      order,
      'cancel',
      extra: const {'reason': 'Cancelled from mobile dispatch.'},
      successMessage: 'Order cancelled',
    );
  }

  Future<void> _scheduleAsap(
    BuildContext parentContext,
    WidgetRef ref,
    OrderSummary order,
  ) async {
    final pickupStart = await showDialog<DateTime>(
      context: parentContext,
      builder: (context) => const _AsapScheduleDialog(),
    );
    if (pickupStart == null) return;
    try {
      await ref.read(adminRepositoryProvider).runDispatchAction(
        orderId: order.id,
        action: 'acknowledge_asap',
        extra: {'asap_pickup_start': pickupStart.toIso8601String()},
      );
      ref.invalidate(adminDispatchCenterProvider);
      if (parentContext.mounted) {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          const SnackBar(content: Text('ASAP pickup scheduled')),
        );
      }
    } catch (error) {
      if (parentContext.mounted) {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          SnackBar(content: Text('ASAP scheduling failed: $error')),
        );
      }
    }
  }
}

class _AsapScheduleDialog extends StatefulWidget {
  const _AsapScheduleDialog();

  @override
  State<_AsapScheduleDialog> createState() => _AsapScheduleDialogState();
}

class _AsapScheduleDialogState extends State<_AsapScheduleDialog> {
  late DateTime _date;
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    final nextHour = DateTime.now().add(const Duration(hours: 1));
    _date = DateTime(nextHour.year, nextHour.month, nextHour.day);
    _time = TimeOfDay(hour: nextHour.hour, minute: 0);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Schedule ASAP Pickup'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Pickup day'),
            subtitle: Text('${_date.month}/${_date.day}/${_date.year}'),
            onTap: _pickDate,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule_outlined),
            title: const Text('Start time'),
            subtitle: Text(_time.format(context)),
            onTap: _pickTime,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(DateTime(
            _date.year,
            _date.month,
            _date.day,
            _time.hour,
            _time.minute,
          )),
          child: const Text('Schedule'),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.pkmnGrayDark),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body(size: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _TradeInList extends StatelessWidget {
  const _TradeInList({required this.tradeIns});

  final List<Map<String, dynamic>> tradeIns;

  @override
  Widget build(BuildContext context) {
    if (tradeIns.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          PkCard(child: Text('No standalone trades right now.'))
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tradeIns.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final trade = tradeIns[index];
        final user = asMap(trade['user']);
        final items = asMapList(trade['items']);
        final email =
            asString(user['email'], fallback: asString(trade['user_email']));
        return PkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Trade #${asString(trade['id'])}',
                      style: AppTextStyles.heading(size: 16),
                    ),
                  ),
                  PkStatusBadge(
                      status: asString(trade['status'],
                          fallback: 'pending_review')),
                ],
              ),
              const SizedBox(height: 8),
              Text(email.isEmpty ? 'Customer not attached' : email,
                  style: AppTextStyles.body()),
              const SizedBox(height: 6),
              Text(
                items.isEmpty
                    ? 'No card summary returned'
                    : items
                        .map((item) => asString(item['card_name'],
                            fallback: asString(item['name'])))
                        .where((name) => name.isNotEmpty)
                        .join(', '),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body(color: AppColors.pkmnText),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DispatchError extends StatelessWidget {
  const _DispatchError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: PkCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.pkmnRed, size: 40),
              const SizedBox(height: 10),
              Text('Dispatch failed to load',
                  style: AppTextStyles.heading(size: 18)),
              const SizedBox(height: 6),
              Text(message,
                  textAlign: TextAlign.center, style: AppTextStyles.body()),
              const SizedBox(height: 14),
              PkButton(label: 'Retry', onPressed: onRetry),
            ],
          ),
        ),
      ),
    );
  }
}
