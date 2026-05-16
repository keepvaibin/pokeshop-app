import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/api_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pk_button.dart';
import '../../../../core/widgets/pk_card.dart';
import '../../../../core/widgets/pk_input.dart';
import '../../../../core/widgets/pk_status_badge.dart';
import '../../../checkout/presentation/widgets/timeslot_selector.dart';
import '../../data/trade_in_repository.dart';

class TradeInScreen extends ConsumerStatefulWidget {
  const TradeInScreen({super.key});

  @override
  ConsumerState<TradeInScreen> createState() => _TradeInScreenState();
}

class _TradeInScreenState extends ConsumerState<TradeInScreen> {
  final _cardNameController = TextEditingController();
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();
  final List<TradeCardEntry> _cards = [];
  TimeslotSelection? _timeslot;
  String _payoutType = 'store_credit';
  String _cashMethod = 'venmo';
  bool _submitting = false;
  String? _message;

  @override
  void dispose() {
    _cardNameController.dispose();
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(tradeInHistoryProvider);
    final wallet = ref.watch(walletProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Trade-In')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(tradeInHistoryProvider);
          ref.invalidate(walletProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            wallet.when(
              loading: () => const SizedBox.shrink(),
              error: (error, stackTrace) => const SizedBox.shrink(),
              data: (data) => PkCard(
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet,
                        color: AppColors.pkmnBlue),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text('Store Credit Balance',
                            style: AppTextStyles.heading(size: 16))),
                    Text('\$${data.balance.toStringAsFixed(2)}',
                        style: AppTextStyles.heading(
                            size: 18, color: AppColors.pkmnBlueDark)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            PkCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Submit Cards', style: AppTextStyles.heading(size: 20)),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                          value: 'store_credit', label: Text('Store Credit')),
                      ButtonSegment(value: 'cash', label: Text('Cash')),
                    ],
                    selected: {_payoutType},
                    onSelectionChanged: (value) =>
                        setState(() => _payoutType = value.first),
                  ),
                  if (_payoutType == 'cash') ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: _cashMethod,
                      decoration: const InputDecoration(
                          labelText: 'Cash Payout Method'),
                      items: const [
                        DropdownMenuItem(value: 'venmo', child: Text('Venmo')),
                        DropdownMenuItem(value: 'zelle', child: Text('Zelle')),
                        DropdownMenuItem(
                            value: 'paypal', child: Text('PayPal')),
                      ],
                      onChanged: (value) =>
                          setState(() => _cashMethod = value ?? 'venmo'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TimeslotSelector(
                      value: _timeslot,
                      onChanged: (value) => setState(() => _timeslot = value),
                      emptyMessage:
                          'No drop-off timeslots are currently available.'),
                  const SizedBox(height: 16),
                  PkInput(controller: _cardNameController, label: 'Card Name'),
                  const SizedBox(height: 10),
                  PkInput(
                      controller: _valueController,
                      label: 'Estimated Market Value',
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 10),
                  PkButton(
                      label: 'Add Card',
                      variant: PkButtonVariant.secondary,
                      onPressed: _addCard),
                  const SizedBox(height: 10),
                  ..._cards.map((card) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                          '${card.cardName} - \$${card.estimatedValue.toStringAsFixed(2)}'))),
                  const SizedBox(height: 10),
                  PkInput(
                      controller: _notesController,
                      label: 'Notes',
                      maxLines: 3),
                  if (_message != null) ...[
                    const SizedBox(height: 10),
                    Text(_message!,
                        style: AppTextStyles.body(
                            color: _message!.startsWith('Submitted')
                                ? AppColors.pkmnBlue
                                : AppColors.pkmnRed)),
                  ],
                  const SizedBox(height: 12),
                  PkButton(
                      label: 'Submit Trade-In',
                      loading: _submitting,
                      onPressed: _submitting ? null : _submit,
                      expand: true),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('History', style: AppTextStyles.heading(size: 20)),
            const SizedBox(height: 10),
            history.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => PkCard(child: Text('$error')),
              data: (items) => Column(
                children: items.isEmpty
                    ? [const PkCard(child: Text('No trade-ins yet.'))]
                    : items
                        .map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: PkCard(
                                child: Row(children: [
                              Expanded(
                                  child: Text(
                                      '${item.payoutLabel} • \$${item.estimatedValue.toStringAsFixed(2)}')),
                              PkStatusBadge(status: item.status)
                            ]))))
                        .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addCard() {
    final value = double.tryParse(_valueController.text) ?? 0;
    if (_cardNameController.text.trim().isEmpty || value <= 0) return;
    setState(() {
      _cards.add(TradeCardEntry(
          cardName: _cardNameController.text.trim(), estimatedValue: value));
      _cardNameController.clear();
      _valueController.clear();
    });
  }

  Future<void> _submit() async {
    if (_timeslot == null || _cards.isEmpty) {
      setState(
          () => _message = 'Choose a drop-off time and add at least one card.');
      return;
    }
    setState(() {
      _submitting = true;
      _message = null;
    });
    try {
      await ref.read(tradeInRepositoryProvider).submit(
            timeslot: _timeslot!,
            cards: _cards,
            payoutType: _payoutType,
            cashPaymentMethod: _cashMethod,
            notes: _notesController.text,
          );
      setState(() {
        _cards.clear();
        _notesController.clear();
        _message = 'Submitted. The shop will review your cards.';
      });
      ref.invalidate(tradeInHistoryProvider);
    } catch (error) {
      setState(() => _message = '$error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
