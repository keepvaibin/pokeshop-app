import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/models/api_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pk_button.dart';
import '../../../../core/widgets/pk_card.dart';
import '../../../../core/widgets/pk_network_image.dart';
import '../../../../core/widgets/pk_status_badge.dart';
import '../../data/orders_repository.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderDetailProvider(orderId));
    final isAdminRoute =
        GoRouterState.of(context).matchedLocation.startsWith('/admin');
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt')),
      bottomNavigationBar: order.maybeWhen(
        data: (item) => SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: PkButton(
              label: 'Print Invoice',
              icon: const Icon(Icons.print_outlined),
              onPressed: () => _printInvoice(item),
              expand: true,
            ),
          ),
        ),
        orElse: () => null,
      ),
      body: order.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('$error')),
        data: (item) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(orderDetailProvider(orderId)),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth =
                  constraints.maxWidth >= 760 ? 760.0 : double.infinity;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ReceiptHeader(order: item),
                          const SizedBox(height: 12),
                          _ItemSummary(order: item),
                          const SizedBox(height: 12),
                          _PickupPayment(order: item),
                          const SizedBox(height: 12),
                          _PaymentLedger(order: item),
                          if (isAdminRoute && _isAdjustable(item)) ...[
                            const SizedBox(height: 12),
                            _AdminOrderActions(order: item),
                          ],
                          if (item.counterofferMessage.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _CounterofferCard(
                                message: item.counterofferMessage),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _printInvoice(OrderSummary order) async {
    await Printing.layoutPdf(
      name: 'SCTCG-${order.orderId}.pdf',
      onLayout: (format) => _buildInvoicePdf(order, format),
    );
  }

  bool _isAdjustable(OrderSummary order) {
    return const {
      'pending',
      'cash_needed',
      'trade_review',
      'pending_counteroffer'
    }.contains(order.status);
  }
}

class _ReceiptHeader extends StatelessWidget {
  const _ReceiptHeader({required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    return PkCard(
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
                    Text('Order ${order.orderId}',
                        style: AppTextStyles.heading(size: 21)),
                    if (order.createdAt.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(order.createdAt,
                          style: AppTextStyles.body(size: 12)),
                    ],
                  ],
                ),
              ),
              PkStatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HeaderStat(
                  label: 'Items',
                  value:
                      '${order.items.fold<int>(0, (sum, line) => sum + line.quantity)}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeaderStat(
                    label: 'Total Due', value: _money(order.netDue)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.pkmnGrayLight,
        border: Border.all(color: AppColors.pkmnBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.label(color: AppColors.pkmnGray)),
            const SizedBox(height: 4),
            Text(value, style: AppTextStyles.heading(size: 18)),
          ],
        ),
      ),
    );
  }
}

class _ItemSummary extends StatelessWidget {
  const _ItemSummary({required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    return PkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Items', style: AppTextStyles.heading(size: 18)),
          const SizedBox(height: 10),
          if (order.items.isEmpty)
            Text(
              order.itemsSummary.isEmpty
                  ? 'No item details returned.'
                  : order.itemsSummary,
              style: AppTextStyles.body(),
            )
          else
            for (final line in order.items) _ItemLine(line: line),
        ],
      ),
    );
  }
}

class _ItemLine extends StatelessWidget {
  const _ItemLine({required this.line});

  final OrderLine line;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 68,
            height: 68,
            child: PkNetworkImage(
              imageUrl: line.imageUrl,
              semanticLabel: line.title,
              padding: const EdgeInsets.all(7),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.title, style: AppTextStyles.heading(size: 15)),
                const SizedBox(height: 4),
                Text('${line.quantity} x ${_money(line.price)}',
                    style: AppTextStyles.body(size: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(_money(line.subtotal), style: AppTextStyles.heading(size: 14)),
        ],
      ),
    );
  }
}

class _PickupPayment extends StatelessWidget {
  const _PickupPayment({required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    return PkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pickup & Payment', style: AppTextStyles.heading(size: 18)),
          const SizedBox(height: 10),
          _DetailRow(
            icon: Icons.schedule_outlined,
            label: 'Pickup',
            value: order.pickupLabel.isEmpty
                ? (order.deliveryMethod.isEmpty
                    ? 'Not scheduled'
                    : order.deliveryMethod)
                : order.pickupLabel,
          ),
          const SizedBox(height: 8),
          _DetailRow(
            icon: Icons.payments_outlined,
            label: 'Payment',
            value: _paymentLabel(order.paymentMethod),
          ),
          if (order.couponCode.isNotEmpty) ...[
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.confirmation_number_outlined,
              label: 'Coupon',
              value: order.couponCode,
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.pkmnGrayLight,
        border: Border.all(color: AppColors.pkmnBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.pkmnBlue, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label.toUpperCase(),
                      style: AppTextStyles.label(color: AppColors.pkmnGray)),
                  const SizedBox(height: 4),
                  Text(
                    value.isEmpty ? 'Not set' : value,
                    style: AppTextStyles.heading(size: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _paymentLabel(String value) {
  return switch (value) {
    'venmo' => 'Venmo',
    'zelle' => 'Zelle',
    'paypal' => 'PayPal',
    'cash' => 'Cash',
    'trade' => 'Trade-In',
    'cash_plus_trade' => 'Trade + Balance',
    _ => value.replaceAll('_', ' '),
  };
}

class _PaymentLedger extends StatelessWidget {
  const _PaymentLedger({required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    return PkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Summary', style: AppTextStyles.heading(size: 18)),
          const SizedBox(height: 10),
          if (order.taxSummary != null) ...[
            if (order.discountApplied > 0) ...[
              _LedgerRow(label: 'Items total', value: _money(order.total)),
              _LedgerRow(
                  label: 'Coupon Discount',
                  value: '-${_money(order.discountApplied)}'),
            ],
            _LedgerRow(
                label: 'Subtotal before tax',
                value: _money(order.taxSummary!.preTaxSubtotal)),
            _LedgerRow(
                label: 'Sales tax', value: _money(order.taxSummary!.salesTax)),
            _LedgerRow(
                label: 'Total after tax',
                value: _money(order.taxSummary!.grossTotal)),
          ] else ...[
            _LedgerRow(label: 'Subtotal', value: _money(order.total)),
            if (order.discountApplied > 0)
              _LedgerRow(
                  label: 'Coupon Discount',
                  value: '-${_money(order.discountApplied)}'),
          ],
          if (order.tradeCreditApplied > 0)
            _LedgerRow(
                label: 'Trade Credit Applied',
                value: '-${_money(order.tradeCreditApplied)}'),
          if (order.storeCreditApplied > 0)
            _LedgerRow(
                label: 'Store Credit Applied',
                value: '-${_money(order.storeCreditApplied)}'),
          const Divider(),
          _LedgerRow(
            label: 'Total Due',
            value: _money(order.netDue),
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow(
      {required this.label, required this.value, this.emphasized = false});

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? AppTextStyles.heading(size: 18, color: AppColors.pkmnBlueDark)
        : AppTextStyles.body(color: AppColors.pkmnText);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _CounterofferCard extends StatelessWidget {
  const _CounterofferCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return PkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Counteroffer', style: AppTextStyles.heading(size: 18)),
          const SizedBox(height: 8),
          Text(message, style: AppTextStyles.body(color: AppColors.pkmnText)),
        ],
      ),
    );
  }
}

class _AdminOrderActions extends ConsumerWidget {
  const _AdminOrderActions({required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cancellableLines = order.items
        .where((line) => line.orderItemIds.isNotEmpty || line.id != null)
        .toList(growable: false);
    return PkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Admin Adjustments', style: AppTextStyles.heading(size: 18)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PkButton(
                label: 'Cancel Order',
                icon: const Icon(Icons.cancel_outlined),
                variant: PkButtonVariant.destructive,
                onPressed: () => _cancelOrder(context, ref),
              ),
              PkButton(
                label: 'Cancel Items',
                icon: const Icon(Icons.remove_shopping_cart_outlined),
                variant: PkButtonVariant.secondary,
                onPressed: cancellableLines.isEmpty
                    ? null
                    : () => _cancelItems(context, ref, cancellableLines),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder(BuildContext context, WidgetRef ref) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => const _ReasonDialog(title: 'Cancel Order'),
    );
    if (reason == null || reason.trim().isEmpty) return;
    try {
      await ref.read(ordersRepositoryProvider).adminCancelOrder(
            orderId: order.orderId,
            reason: reason.trim(),
          );
      ref.invalidate(orderDetailProvider(order.orderId));
      ref.invalidate(adminOrdersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order cancelled.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error')),
        );
      }
    }
  }

  Future<void> _cancelItems(
    BuildContext context,
    WidgetRef ref,
    List<OrderLine> lines,
  ) async {
    final result = await showDialog<({List<int> ids, String reason})>(
      context: context,
      builder: (context) => _CancelItemsDialog(lines: lines),
    );
    if (result == null || result.ids.isEmpty) return;
    try {
      await ref.read(ordersRepositoryProvider).adminCancelOrderItems(
            orderId: order.orderId,
            orderItemIds: result.ids,
            reason: result.reason,
          );
      ref.invalidate(orderDetailProvider(order.orderId));
      ref.invalidate(adminOrdersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Items cancelled.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error')),
        );
      }
    }
  }
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({required this.title});

  final String title;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        minLines: 3,
        maxLines: 5,
        decoration: const InputDecoration(labelText: 'Reason'),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final reason = _controller.text.trim();
            if (reason.isEmpty) return;
            Navigator.of(context).pop(reason);
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

class _CancelItemsDialog extends StatefulWidget {
  const _CancelItemsDialog({required this.lines});

  final List<OrderLine> lines;

  @override
  State<_CancelItemsDialog> createState() => _CancelItemsDialogState();
}

class _CancelItemsDialogState extends State<_CancelItemsDialog> {
  final _reasonController = TextEditingController();
  final Set<OrderLine> _selected = {};

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancel Items'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final line in widget.lines)
                CheckboxListTile(
                  value: _selected.contains(line),
                  onChanged: (value) => setState(() {
                    if (value == true) {
                      _selected.add(line);
                    } else {
                      _selected.remove(line);
                    }
                  }),
                  title: Text(line.title),
                  subtitle: Text('${line.quantity} x ${_money(line.price)}'),
                ),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Reason'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final reason = _reasonController.text.trim();
            if (_selected.isEmpty || reason.isEmpty) return;
            final ids = _selected.expand((line) {
              if (line.orderItemIds.isNotEmpty) return line.orderItemIds;
              final id = line.id;
              return id == null ? const <int>[] : [id];
            }).toList();
            Navigator.of(context).pop((ids: ids, reason: reason));
          },
          child: const Text('Cancel Selected'),
        ),
      ],
    );
  }
}

Future<Uint8List> _buildInvoicePdf(
    OrderSummary order, PdfPageFormat format) async {
  final document = pw.Document();
  document.addPage(
    pw.MultiPage(
      pageFormat: format,
      margin: const pw.EdgeInsets.all(36),
      build: (context) => [
        pw.Text('Santa Cruz TCG',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Text('Invoice ${order.orderId}'),
        pw.Text('Status: ${order.status.replaceAll('_', ' ')}'),
        if (order.createdAt.isNotEmpty) pw.Text('Date: ${order.createdAt}'),
        pw.SizedBox(height: 18),
        pw.Text('Items',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: const ['Item', 'Qty', 'Each', 'Subtotal'],
          data: order.items
              .map((line) => [
                    line.title,
                    '${line.quantity}',
                    _money(line.price),
                    _money(line.subtotal),
                  ])
              .toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellAlignment: pw.Alignment.centerLeft,
          cellAlignments: const {
            1: pw.Alignment.centerRight,
            2: pw.Alignment.centerRight,
            3: pw.Alignment.centerRight,
          },
        ),
        pw.SizedBox(height: 18),
        pw.Text(
            'Pickup: ${order.pickupLabel.isEmpty ? order.deliveryMethod : order.pickupLabel}'),
        pw.Text('Payment: ${order.paymentMethod.replaceAll('_', ' ')}'),
        pw.SizedBox(height: 18),
        if (order.taxSummary != null) ...[
          if (order.discountApplied > 0) ...[
            _pdfLedgerRow('Items total', order.total),
            _pdfLedgerRow('Discount', -order.discountApplied),
          ],
          _pdfLedgerRow(
              'Subtotal before tax', order.taxSummary!.preTaxSubtotal),
          _pdfLedgerRow('Sales tax', order.taxSummary!.salesTax),
          _pdfLedgerRow('Total after tax', order.taxSummary!.grossTotal),
        ] else ...[
          _pdfLedgerRow('Subtotal', order.total),
          if (order.discountApplied > 0)
            _pdfLedgerRow('Discount', -order.discountApplied),
        ],
        if (order.tradeCreditApplied > 0)
          _pdfLedgerRow('Trade credit', -order.tradeCreditApplied),
        if (order.storeCreditApplied > 0)
          _pdfLedgerRow('Store credit', -order.storeCreditApplied),
        pw.Divider(),
        _pdfLedgerRow('Net due', order.netDue, emphasized: true),
      ],
    ),
  );
  return document.save();
}

pw.Widget _pdfLedgerRow(String label, double value, {bool emphasized = false}) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.end,
    children: [
      pw.SizedBox(
        width: 120,
        child: pw.Text(label,
            style: pw.TextStyle(
                fontWeight:
                    emphasized ? pw.FontWeight.bold : pw.FontWeight.normal)),
      ),
      pw.SizedBox(
        width: 80,
        child: pw.Text(
          _money(value),
          textAlign: pw.TextAlign.right,
          style: pw.TextStyle(
              fontWeight:
                  emphasized ? pw.FontWeight.bold : pw.FontWeight.normal),
        ),
      ),
    ],
  );
}

String _money(double value) => '\$${value.toStringAsFixed(2)}';
