import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/api_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pk_button.dart';
import '../../../../core/widgets/pk_card.dart';
import '../../../../core/widgets/pk_input.dart';
import '../../../../core/widgets/pk_network_image.dart';
import '../../../../core/widgets/pk_status_badge.dart';
import '../../../checkout/presentation/widgets/timeslot_selector.dart';
import '../../../shop/data/shop_repository.dart';
import '../../data/trade_in_repository.dart';
import '../widgets/card_search_sheet.dart';

// ---------------------------------------------------------------------------
// Condition helpers (mirrors frontend TradeCardForm.tsx)
// ---------------------------------------------------------------------------
const _kConditions = [
  (value: 'near_mint', label: 'Near Mint', multiplier: 1.0),
  (value: 'lightly_played', label: 'Lightly Played', multiplier: 0.85),
  (value: 'moderately_played', label: 'Moderately Played', multiplier: 0.70),
  (value: 'heavily_played', label: 'Heavily Played', multiplier: 0.50),
  (value: 'damaged', label: 'Damaged', multiplier: 0.30),
];

double _conditionMultiplier(String condition) => _kConditions
    .firstWhere((c) => c.value == condition,
        orElse: () => _kConditions.first)
    .multiplier;

/// Returns a copy of [entry] with [newCondition] applied and estimated_value
/// recalculated from base_market_price if available.
TradeCardEntry _withCondition(TradeCardEntry entry, String newCondition) {
  final base = entry.baseMarketPrice;
  final estimated = (base != null && base > 0)
      ? double.parse(
          (base * _conditionMultiplier(newCondition)).toStringAsFixed(2))
      : entry.estimatedValue;
  return TradeCardEntry(
    cardName: entry.cardName,
    estimatedValue: estimated,
    setName: entry.setName,
    cardNumber: entry.cardNumber,
    condition: newCondition,
    quantity: entry.quantity,
    imageUrl: entry.imageUrl,
    tcgProductId: entry.tcgProductId,
    tcgSubType: entry.tcgSubType,
    baseMarketPrice: entry.baseMarketPrice,
    tcgplayerUrl: entry.tcgplayerUrl,
  );
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
class TradeInScreen extends ConsumerStatefulWidget {
  const TradeInScreen({super.key});

  @override
  ConsumerState<TradeInScreen> createState() => _TradeInScreenState();
}

class _TradeInScreenState extends ConsumerState<TradeInScreen> {
  final _notesController = TextEditingController();
  final List<TradeCardEntry> _cards = [];
  TimeslotSelection? _timeslot;
  String _payoutType = 'store_credit';
  String _cashMethod = 'venmo';
  bool _submitting = false;
  String? _message;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Actions
  // -------------------------------------------------------------------------

  void _openCardSearch() async {
    final result = await showModalBottomSheet<TradeCardEntry>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => CardSearchSheet(
        repository: ref.read(tradeInRepositoryProvider),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _cards.add(result);
        _message = null;
      });
    }
  }

  void _openWantedCards() async {
    final result = await showModalBottomSheet<TradeCardEntry>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => CardSearchSheet(
        repository: ref.read(tradeInRepositoryProvider),
        wantedMode: true,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _cards.add(result);
        _message = null;
      });
    }
  }

  void _updateCondition(int index, String condition) {
    setState(() => _cards[index] = _withCondition(_cards[index], condition));
  }

  void _removeCard(int index) {
    setState(() => _cards.removeAt(index));
  }

  Future<void> _submit() async {
    if (_timeslot == null || _cards.isEmpty) {
      setState(() =>
          _message = 'Choose a drop-off timeslot and add at least one card.');
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
        _timeslot = null;
        _notesController.clear();
        _message = 'Submitted! We\'ll review your cards and reach out on Discord.';
      });
      ref.invalidate(tradeInHistoryProvider);
    } catch (error) {
      setState(() => _message = '$error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(tradeInHistoryProvider);
    final wallet = ref.watch(walletProvider);
    final settingsAsync = ref.watch(storeSettingsProvider);
    final creditRate =
        settingsAsync.valueOrNull?.tradeCreditPercentage ?? 85.0;

    final totalValue =
        _cards.fold(0.0, (sum, c) => sum + c.estimatedValue * c.quantity);
    final estimatedCredit = totalValue * creditRate / 100;

    return Scaffold(
      appBar: AppBar(title: const Text('Trade-In')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(tradeInHistoryProvider);
          ref.invalidate(walletProvider);
          ref.invalidate(storeSettingsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ----- Wallet -----
            wallet.when(
              loading: () => const SizedBox.shrink(),
              error: (error, stackTrace) => const SizedBox.shrink(),
              data: (data) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PkCard(
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
            ),
            // ----- Submit form -----
            PkCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Submit Cards', style: AppTextStyles.heading(size: 20)),
                  const SizedBox(height: 12),
                  // Payout type
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
                  // Cards header
                  Row(
                    children: [
                      Text('Cards (${_cards.length})',
                          style: AppTextStyles.heading(size: 16)),
                      const Spacer(),
                      if (_cards.isNotEmpty)
                        Text(
                          '~\$${estimatedCredit.toStringAsFixed(2)} credit',
                          style: AppTextStyles.body(
                              size: 12, color: AppColors.pkmnBlue),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Added cards
                  ..._cards.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _TradeCardTile(
                          entry: e.value,
                          creditRate: creditRate,
                          onConditionChanged: (c) =>
                              _updateCondition(e.key, c),
                          onRemove: () => _removeCard(e.key),
                        ),
                      )),
                  // Search / Favorites buttons
                  Row(
                    children: [
                      Expanded(
                        child: PkButton(
                          label: 'Search for Card',
                          icon: const Icon(Icons.search),
                          onPressed: _openCardSearch,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: PkButton(
                          label: 'Favorites',
                          icon: const Icon(Icons.favorite_border),
                          variant: PkButtonVariant.secondary,
                          onPressed: _openWantedCards,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  PkInput(
                      controller: _notesController,
                      label: 'Notes',
                      maxLines: 3),
                  if (_message != null) ...[
                    const SizedBox(height: 10),
                    Text(_message!,
                        style: AppTextStyles.body(
                            color: _message!.startsWith('Submitted')
                                ? Colors.green.shade700
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
}

// ---------------------------------------------------------------------------
// Card tile shown in the trade-in list
// ---------------------------------------------------------------------------
class _TradeCardTile extends StatelessWidget {
  const _TradeCardTile({
    required this.entry,
    required this.creditRate,
    required this.onConditionChanged,
    required this.onRemove,
  });

  final TradeCardEntry entry;
  final double creditRate;
  final ValueChanged<String> onConditionChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasPrice = entry.baseMarketPrice != null && entry.baseMarketPrice! > 0;
    final condLabel = _kConditions
        .firstWhere((c) => c.value == entry.condition,
            orElse: () => _kConditions.first)
        .label;
    final credit = entry.estimatedValue * creditRate / 100;

    return PkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: image + info + remove
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 52,
                height: 70,
                child: PkNetworkImage(
                  imageUrl: entry.imageUrl.isEmpty ? null : entry.imageUrl,
                  semanticLabel: entry.cardName,
                  padding: const EdgeInsets.all(2),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(entry.cardName,
                              style: AppTextStyles.heading(size: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (hasPrice)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              border: Border.all(
                                  color: Colors.green.shade300, width: 0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('TCG VERIFIED',
                                style: AppTextStyles.label(
                                    color: Colors.green.shade700)
                                    .copyWith(fontSize: 9)),
                          ),
                      ],
                    ),
                    if (entry.setName.isNotEmpty || entry.cardNumber.isNotEmpty)
                      Text(
                        [
                          if (entry.setName.isNotEmpty) entry.setName,
                          if (entry.cardNumber.isNotEmpty) '#${entry.cardNumber}',
                        ].join(' · '),
                        style: AppTextStyles.body(size: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (entry.tcgSubType.isNotEmpty)
                      Text(entry.tcgSubType,
                          style: AppTextStyles.body(size: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.remove_circle_outline,
                    color: AppColors.pkmnRed, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Condition dropdown
          DropdownButtonFormField<String>(
            initialValue: entry.condition,
            isDense: true,
            decoration: const InputDecoration(
              labelText: 'Condition',
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _kConditions
                .map((c) => DropdownMenuItem(
                    value: c.value, child: Text(c.label)))
                .toList(),
            onChanged: (v) {
              if (v != null) onConditionChanged(v);
            },
          ),
          const SizedBox(height: 8),
          // Price info
          if (hasPrice)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Market Price (NM):',
                          style: AppTextStyles.body(size: 12)),
                      Text('\$${entry.baseMarketPrice!.toStringAsFixed(2)}',
                          style: AppTextStyles.body(
                              size: 12,
                              weight: FontWeight.w700,
                              color: AppColors.pkmnText)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$condLabel (×${_conditionMultiplier(entry.condition).toStringAsFixed(2)}):',
                          style: AppTextStyles.body(size: 12)),
                      Text('\$${entry.estimatedValue.toStringAsFixed(2)}',
                          style: AppTextStyles.body(
                              size: 12,
                              weight: FontWeight.w700,
                              color: AppColors.pkmnText)),
                    ],
                  ),
                  const Divider(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          'Trade Credit (${creditRate.toStringAsFixed(0)}%):',
                          style: AppTextStyles.body(
                              size: 12,
                              weight: FontWeight.w700,
                              color: Colors.green.shade700)),
                      Text('\$${credit.toStringAsFixed(2)}',
                          style: AppTextStyles.body(
                              size: 12,
                              weight: FontWeight.w700,
                              color: Colors.green.shade700)),
                    ],
                  ),
                ],
              ),
            )
          else if (entry.estimatedValue > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Estimated Value:',
                    style: AppTextStyles.body(size: 12)),
                Text('\$${entry.estimatedValue.toStringAsFixed(2)}',
                    style: AppTextStyles.body(
                        size: 12,
                        weight: FontWeight.w700,
                        color: AppColors.pkmnText)),
              ],
            ),
        ],
      ),
    );
  }
}


