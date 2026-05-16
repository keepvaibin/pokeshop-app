import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/json_helpers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pk_button.dart';
import '../../../../core/widgets/pk_card.dart';
import '../../../../core/widgets/pk_status_badge.dart';
import '../../data/admin_repository.dart';

class AdminTradeInsScreen extends ConsumerStatefulWidget {
  const AdminTradeInsScreen({super.key});

  @override
  ConsumerState<AdminTradeInsScreen> createState() =>
      _AdminTradeInsScreenState();
}

class _AdminTradeInsScreenState extends ConsumerState<AdminTradeInsScreen> {
  String _status = '';
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trade-Ins'),
        actions: [
          IconButton(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh')
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && !snapshot.hasData) {
            return Center(child: Text('${snapshot.error}'));
          }
          final trades = snapshot.data ?? const <Map<String, dynamic>>[];
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: trades.length + 1,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Trade desk',
                          style: AppTextStyles.heading(size: 24)),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(
                              value: '', child: Text('All statuses')),
                          DropdownMenuItem(
                              value: 'pending_review',
                              child: Text('Pending review')),
                          DropdownMenuItem(
                              value: 'pending_counteroffer',
                              child: Text('Counteroffer')),
                          DropdownMenuItem(
                              value: 'approved_pending_receipt',
                              child: Text('Approved / awaiting receipt')),
                          DropdownMenuItem(
                              value: 'completed', child: Text('Completed')),
                          DropdownMenuItem(
                              value: 'rejected', child: Text('Rejected')),
                        ],
                        onChanged: (value) {
                          setState(() => _status = value ?? '');
                          _refresh();
                        },
                      ),
                    ],
                  );
                }
                return _TradeInCard(
                    trade: trades[index - 1], onAction: _runAction);
              },
            ),
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _load() {
    return ref.read(adminRepositoryProvider).listResource(
          ApiEndpoints.tradeInAdmin,
          queryParameters: _status.isEmpty ? null : {'status': _status},
        );
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  Future<void> _runAction(Map<String, dynamic> trade, String action) async {
    final id = asInt(trade['id']);
    Map<String, dynamic>? payload;
    if (action == 'approve') {
      payload = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => _ApproveDialog(
            defaultAmount: asString(trade['estimated_total_value'])),
      );
    } else if (action == 'reject') {
      payload = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => const _RejectDialog(),
      );
    } else if (action == 'review') {
      payload = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => _CardReviewDialog(trade: trade),
      );
    } else if (action == 'complete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Complete trade-in?'),
          content: const Text(
              'This funds the customer wallet when payout type is store credit.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Complete')),
          ],
        ),
      );
      if (confirmed != true) return;
      payload = const <String, dynamic>{};
    }
    if (payload == null) return;
    try {
      await ref
          .read(adminRepositoryProvider)
          .runTradeInAction(id: id, action: action, payload: payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Trade-in updated.')));
      _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}

class _TradeInCard extends StatelessWidget {
  const _TradeInCard({required this.trade, required this.onAction});

  final Map<String, dynamic> trade;
  final Future<void> Function(Map<String, dynamic> trade, String action)
      onAction;

  @override
  Widget build(BuildContext context) {
    final items = asMapList(trade['items']);
    final status = asString(trade['status']);
    return PkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: Text('Trade-In #${asInt(trade['id'])}',
                      style: AppTextStyles.heading(size: 17))),
              PkStatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 8),
          Text(asString(trade['user_email']),
              style: AppTextStyles.body(size: 13)),
          if (asString(trade['discord_handle']).isNotEmpty)
            Text(asString(trade['discord_handle']),
                style: AppTextStyles.body(
                    size: 12, color: AppColors.pkmnGrayDark)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(
                  label: 'Estimate',
                  value:
                      '\$${asDouble(trade['estimated_total_value']).toStringAsFixed(2)}'),
              _Chip(
                  label: 'Payout',
                  value:
                      '\$${asDouble(trade['final_payout_value']).toStringAsFixed(2)}'),
              _Chip(
                  label: 'Cards',
                  value:
                      '${items.fold<int>(0, (sum, item) => sum + asInt(item['quantity'], fallback: 1))}'),
              _Chip(
                  label: 'Pickup',
                  value: asString(trade['pickup_label'], fallback: '-')),
            ],
          ),
          const SizedBox(height: 10),
          ...items.take(4).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                    '${asString(item['card_name'])} x${asInt(item['quantity'], fallback: 1)} • ${asString(item['condition'])}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              )),
          if (items.length > 4)
            Text('+${items.length - 4} more cards',
                style: AppTextStyles.body(
                    size: 12, color: AppColors.pkmnGrayDark)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (status == 'pending_review')
                PkButton(
                    label: 'Review Cards',
                    icon: const Icon(Icons.fact_check_outlined),
                    variant: PkButtonVariant.secondary,
                    onPressed: () => onAction(trade, 'review')),
              if (status == 'pending_review')
                PkButton(
                    label: 'Approve',
                    icon: const Icon(Icons.check),
                    onPressed: () => onAction(trade, 'approve')),
              if (status == 'approved_pending_receipt')
                PkButton(
                    label: 'Complete',
                    icon: const Icon(Icons.done_all),
                    onPressed: () => onAction(trade, 'complete')),
              if ({
                'pending_review',
                'pending_counteroffer',
                'approved_pending_receipt'
              }.contains(status))
                PkButton(
                    label: 'Reject',
                    icon: const Icon(Icons.close),
                    variant: PkButtonVariant.destructive,
                    onPressed: () => onAction(trade, 'reject')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
          color: AppColors.pkmnGrayLight,
          borderRadius: BorderRadius.circular(8)),
      child: Text('$label: $value', style: AppTextStyles.body(size: 12)),
    );
  }
}

class _ApproveDialog extends StatefulWidget {
  const _ApproveDialog({required this.defaultAmount});

  final String defaultAmount;

  @override
  State<_ApproveDialog> createState() => _ApproveDialogState();
}

class _ApproveDialogState extends State<_ApproveDialog> {
  late final TextEditingController _amountController =
      TextEditingController(text: widget.defaultAmount);
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Approve Trade-In'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Final payout')),
          const SizedBox(height: 10),
          TextField(
              controller: _notesController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Admin notes')),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop({
            'final_payout_value': _amountController.text.trim(),
            'admin_notes': _notesController.text.trim()
          }),
          child: const Text('Approve'),
        ),
      ],
    );
  }
}

class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject Trade-In'),
      content: TextField(
          controller: _notesController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Reason')),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.of(context)
                .pop({'admin_notes': _notesController.text.trim()}),
            child: const Text('Reject')),
      ],
    );
  }
}

class _CardReviewDialog extends StatefulWidget {
  const _CardReviewDialog({required this.trade});

  final Map<String, dynamic> trade;

  @override
  State<_CardReviewDialog> createState() => _CardReviewDialogState();
}

class _CardReviewDialogState extends State<_CardReviewDialog> {
  final Map<int, bool> _accepted = {};
  final Map<int, TextEditingController> _overrideControllers = {};
  final _messageController = TextEditingController();
  bool _sendCounteroffer = false;

  List<Map<String, dynamic>> get _items => asMapList(widget.trade['items']);

  @override
  void initState() {
    super.initState();
    for (final item in _items) {
      final id = asInt(item['id']);
      _accepted[id] = true;
      _overrideControllers[id] =
          TextEditingController(text: asString(item['admin_override_value']));
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    for (final controller in _overrideControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Review Cards'),
          actions: [TextButton(onPressed: _submit, child: const Text('Save'))],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final item in _items) _cardDecision(item),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _sendCounteroffer,
              onChanged: (value) => setState(() => _sendCounteroffer = value),
              title: const Text('Send counteroffer'),
            ),
            TextField(
              controller: _messageController,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Message / notes'),
            ),
            const SizedBox(height: 16),
            PkButton(label: 'Save Review', onPressed: _submit, expand: true),
          ],
        ),
      ),
    );
  }

  Widget _cardDecision(Map<String, dynamic> item) {
    final id = asInt(item['id']);
    final accepted = _accepted[id] ?? true;
    return PkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(asString(item['card_name']),
              style: AppTextStyles.heading(size: 16)),
          const SizedBox(height: 4),
          Text(
              '${asString(item['set_name'])} • ${asString(item['condition'])} • qty ${asInt(item['quantity'], fallback: 1)}'),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Accept')),
              ButtonSegment(value: false, label: Text('Reject')),
            ],
            selected: {accepted},
            onSelectionChanged: (value) =>
                setState(() => _accepted[id] = value.first),
          ),
          if (accepted) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _overrideControllers[id],
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: 'Override value',
                  hintText: asString(item['user_estimated_price'])),
            ),
          ],
        ],
      ),
    );
  }

  void _submit() {
    final decisions = <String, dynamic>{};
    for (final item in _items) {
      final id = asInt(item['id']);
      final accepted = _accepted[id] ?? true;
      final overrideText = _overrideControllers[id]?.text.trim() ?? '';
      decisions['$id'] = {
        'decision': accepted ? 'accept' : 'reject',
        if (accepted && overrideText.isNotEmpty)
          'overridden_value': overrideText,
      };
    }
    Navigator.of(context).pop({
      'card_decisions': decisions,
      'send_counteroffer': _sendCounteroffer,
      'counteroffer_message': _messageController.text.trim(),
    });
  }
}
