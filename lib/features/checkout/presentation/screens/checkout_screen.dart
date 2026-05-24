import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/api_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pk_button.dart';
import '../../../../core/widgets/pk_card.dart';
import '../../../../core/widgets/pk_input.dart';
import '../../../cart/presentation/providers/cart_controller.dart';
import '../../../trade_in/data/trade_in_repository.dart';
import '../../../trade_in/presentation/widgets/card_search_sheet.dart';
import '../../../shop/data/shop_repository.dart';
import '../providers/checkout_controller.dart';
import '../widgets/timeslot_selector.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkout = ref.watch(checkoutControllerProvider);
    final controller = ref.read(checkoutControllerProvider.notifier);
    final cart = ref.watch(cartControllerProvider);
    final settings = ref.watch(storeSettingsProvider);
    final wallet = ref.watch(walletProvider);

    if (checkout.placedOrder != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Placed')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: PkCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.pkmnBlue, size: 64),
                  const SizedBox(height: 12),
                  Text('Reservation confirmed',
                      style: AppTextStyles.heading(size: 24)),
                  const SizedBox(height: 8),
                  Text(checkout.placedOrder!.orderId,
                      style: AppTextStyles.body()),
                  const SizedBox(height: 16),
                  PkButton(
                      label: 'View Orders',
                      onPressed: () => context.go('/orders')),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(storeSettingsProvider);
          ref.invalidate(recurringTimeslotsProvider);
          ref.invalidate(walletProvider);
        },
        child: cart.lines.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 160),
                  Center(
                    child: PkButton(
                        label: 'Return to Shop',
                        onPressed: () => context.go('/shop')),
                  ),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  _OrderSummary(
                    lines: cart.lines,
                    checkout: checkout,
                    settings: settings.valueOrNull,
                  ),
                  const SizedBox(height: 12),
                  _DeliverySection(checkout: checkout, controller: controller),
                  const SizedBox(height: 12),
                  _PaymentSection(
                    checkout: checkout,
                    controller: controller,
                    settings: settings.valueOrNull,
                  ),
                  const SizedBox(height: 12),
                  _StoreCreditSection(
                    checkout: checkout,
                    controller: controller,
                    wallet: wallet,
                  ),
                  if (checkout.paymentMethod == 'trade') ...[
                    const SizedBox(height: 12),
                    _TradeStep(
                      checkout: checkout,
                      controller: controller,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _CouponStep(
                    couponController: _couponController,
                    checkout: checkout,
                    controller: controller,
                  ),
                  if (checkout.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    PkCard(
                      child: Text(checkout.errorMessage!,
                          style: AppTextStyles.body(color: AppColors.pkmnRed)),
                    ),
                  ],
                  const SizedBox(height: 14),
                  PkButton(
                    label: 'Place Order',
                    loading: checkout.submitting,
                    onPressed:
                        checkout.submitting ? null : controller.placeOrder,
                    expand: true,
                  ),
                ],
              ),
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({
    required this.lines,
    required this.checkout,
    required this.settings,
  });

  final List<CartLine> lines;
  final CheckoutState checkout;
  final StoreSettings? settings;

  @override
  Widget build(BuildContext context) {
    final total = lines.fold<double>(0, (sum, line) => sum + line.subtotal);
    final discount = checkout.coupon?.computedDiscount ?? 0;
    final discountedTotal =
        (total - discount).clamp(0, double.infinity).toDouble();
    final tax = TaxDisplay.split(
        discountedTotal, settings?.salesTaxRatePercent ?? 9.25);
    return PkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Summary', style: AppTextStyles.heading(size: 20)),
          const SizedBox(height: 10),
          ...lines.map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('${line.item.title} x${line.quantity}',
                          style: AppTextStyles.body()),
                    ),
                    Text(formatMoney(line.subtotal),
                        style: AppTextStyles.heading(size: 13)),
                  ],
                ),
              )),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal before tax',
                  style: AppTextStyles.heading(size: 18)),
              Text(formatMoney(tax.preTaxSubtotal),
                  style: AppTextStyles.heading(
                      size: 18, color: AppColors.pkmnBlueDark)),
            ],
          ),
          if (discount > 0) ...[
            const SizedBox(height: 6),
            _CheckoutLedgerRow(label: 'Items total', value: formatMoney(total)),
            _CheckoutLedgerRow(
                label: 'Coupon discount', value: '-${formatMoney(discount)}'),
          ],
          const SizedBox(height: 6),
          _CheckoutLedgerRow(
              label: 'Sales tax', value: formatMoney(tax.salesTax)),
          _CheckoutLedgerRow(
              label: 'Total after tax',
              value: formatMoney(discountedTotal),
              emphasized: true),
        ],
      ),
    );
  }
}

class _CheckoutLedgerRow extends StatelessWidget {
  const _CheckoutLedgerRow(
      {required this.label, required this.value, this.emphasized = false});

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? AppTextStyles.heading(size: 14)
        : AppTextStyles.body(size: 13);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label, style: style), Text(value, style: style)],
    );
  }
}

class _DeliverySection extends StatelessWidget {
  const _DeliverySection({required this.checkout, required this.controller});

  final CheckoutState checkout;
  final CheckoutController controller;

  @override
  Widget build(BuildContext context) {
    return PkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Pickup', style: AppTextStyles.heading(size: 20)),
          const SizedBox(height: 10),
          _ChoiceTiles(
            options: const {
              'asap': 'ASAP Downtown Pickup',
              'scheduled': 'Scheduled Campus Pickup',
            },
            value: checkout.deliveryMethod,
            onChanged: controller.setDelivery,
          ),
          if (checkout.deliveryMethod == 'asap') ...[
            const SizedBox(height: 10),
            Text(
              'We will prepare your order for downtown pickup and send updates when it is ready.',
              style: AppTextStyles.body(size: 13),
            ),
          ],
          if (checkout.deliveryMethod == 'scheduled') ...[
            const SizedBox(height: 14),
            TimeslotSelector(
              value: checkout.timeslot,
              onChanged: controller.setTimeslot,
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentSection extends StatelessWidget {
  const _PaymentSection({
    required this.checkout,
    required this.controller,
    required this.settings,
  });

  final CheckoutState checkout;
  final CheckoutController controller;
  final StoreSettings? settings;

  @override
  Widget build(BuildContext context) {
    final options = <String, String>{
      if (settings?.payVenmo ?? true) 'venmo': 'Venmo',
      if (settings?.payZelle ?? true) 'zelle': 'Zelle',
      if (settings?.payPaypal ?? true) 'paypal': 'PayPal',
      if (settings?.payCash ?? true) 'cash': 'Cash',
      if (settings?.payTrade ?? true) 'trade': 'Trade-In',
    };
    return PkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Payment', style: AppTextStyles.heading(size: 20)),
          const SizedBox(height: 10),
          _ChoiceTiles(
            options: options,
            value: checkout.paymentMethod,
            onChanged: controller.setPayment,
          ),
        ],
      ),
    );
  }
}

class _StoreCreditSection extends StatelessWidget {
  const _StoreCreditSection({
    required this.checkout,
    required this.controller,
    required this.wallet,
  });

  final CheckoutState checkout;
  final CheckoutController controller;
  final AsyncValue<WalletSummary> wallet;

  @override
  Widget build(BuildContext context) {
    return wallet.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (data) => PkCard(
        child: SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: checkout.useStoreCredit,
          onChanged: data.balance > 0 ? controller.setUseStoreCredit : null,
          title: Text('Apply Store Credit',
              style: AppTextStyles.heading(size: 18)),
          subtitle: Text(
            data.balance > 0
                ? '\$${data.balance.toStringAsFixed(2)} available. Any remaining balance uses the payment method above.'
                : 'No store credit is available right now.',
            style: AppTextStyles.body(size: 12),
          ),
        ),
      ),
    );
  }
}

class _ChoiceTiles extends StatelessWidget {
  const _ChoiceTiles({
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final Map<String, String> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.entries.map((entry) {
        final selected = value == entry.key;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => onChanged(entry.key),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: selected ? AppColors.pkmnBlueLight : Colors.white,
                border: Border.all(
                  color: selected ? AppColors.pkmnBlue : AppColors.pkmnBorder,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: selected
                          ? AppColors.pkmnBlue
                          : AppColors.pkmnGrayDark,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(entry.value,
                          style: AppTextStyles.heading(size: 16)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TradeStep extends ConsumerStatefulWidget {
  const _TradeStep({
    required this.checkout,
    required this.controller,
  });

  final CheckoutState checkout;
  final CheckoutController controller;

  @override
  ConsumerState<_TradeStep> createState() => _TradeStepState();
}

class _TradeStepState extends ConsumerState<_TradeStep> {
  void _openSearch({bool wantedMode = false}) async {
    final result = await showModalBottomSheet<TradeCardEntry>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => CardSearchSheet(
        repository: ref.read(tradeInRepositoryProvider),
        wantedMode: wantedMode,
      ),
    );
    if (result != null) widget.controller.addTradeCard(result);
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.checkout.tradeCards;
    return PkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Trade Cards', style: AppTextStyles.heading(size: 20)),
          const SizedBox(height: 4),
          Text(
            'Search the card database to add the cards you want to trade in for this order.',
            style: AppTextStyles.body(size: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: PkButton(
                  label: 'Search for Card',
                  icon: const Icon(Icons.search),
                  onPressed: () => _openSearch(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PkButton(
                  label: 'Favorites',
                  icon: const Icon(Icons.favorite_border),
                  variant: PkButtonVariant.secondary,
                  onPressed: () => _openSearch(wantedMode: true),
                ),
              ),
            ],
          ),
          if (cards.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...cards.indexed.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${entry.$2.cardName}'
                          '${entry.$2.setName.isNotEmpty ? " · ${entry.$2.setName}" : ""}'
                          ' — \$${entry.$2.estimatedValue.toStringAsFixed(2)}',
                          style: AppTextStyles.body(size: 13),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            widget.controller.removeTradeCard(entry.$1),
                        icon: const Icon(Icons.close,
                            color: AppColors.pkmnRed, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _CouponStep extends StatelessWidget {
  const _CouponStep({
    required this.couponController,
    required this.checkout,
    required this.controller,
  });

  final TextEditingController couponController;
  final CheckoutState checkout;
  final CheckoutController controller;

  @override
  Widget build(BuildContext context) {
    return PkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Coupon', style: AppTextStyles.heading(size: 20)),
          const SizedBox(height: 10),
          PkInput(
              controller: couponController,
              label: 'Coupon Code',
              onChanged: controller.setCouponCode),
          const SizedBox(height: 10),
          PkButton(
              label: 'Validate Coupon',
              variant: PkButtonVariant.secondary,
              onPressed: controller.validateCoupon),
          if (checkout.coupon != null) ...[
            const SizedBox(height: 12),
            Text(
              'Discount: \$${checkout.coupon!.computedDiscount.toStringAsFixed(2)}',
              style: AppTextStyles.heading(size: 15, color: AppColors.pkmnBlue),
            ),
          ],
        ],
      ),
    );
  }
}
