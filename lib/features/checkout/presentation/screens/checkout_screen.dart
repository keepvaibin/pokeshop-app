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
import '../providers/checkout_controller.dart';
import '../widgets/timeslot_selector.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _pageController = PageController();
  final _discordController = TextEditingController();
  final _couponController = TextEditingController();
  final _tradeNameController = TextEditingController();
  final _tradeValueController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _discordController.dispose();
    _couponController.dispose();
    _tradeNameController.dispose();
    _tradeValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkout = ref.watch(checkoutControllerProvider);
    final controller = ref.read(checkoutControllerProvider.notifier);
    final cart = ref.watch(cartControllerProvider);

    ref.listen(checkoutControllerProvider.select((value) => value.step),
        (previous, next) {
      if (_pageController.hasClients) {
        _pageController.animateToPage(next,
            duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
      }
    });

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
      body: cart.lines.isEmpty
          ? Center(
              child: PkButton(
                  label: 'Return to Shop',
                  onPressed: () => context.go('/shop')))
          : Column(
              children: [
                _StepHeader(step: checkout.step),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _ReviewStep(lines: cart.lines),
                      _ChoiceStep(
                          title: 'Delivery',
                          options: const {
                            'scheduled': 'Scheduled Campus Pickup',
                            'asap': 'ASAP Downtown Pickup'
                          },
                          value: checkout.deliveryMethod,
                          onChanged: controller.setDelivery),
                      SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: TimeslotSelector(
                              value: checkout.timeslot,
                              onChanged: controller.setTimeslot)),
                      _ChoiceStep(
                          title: 'Payment',
                          options: const {
                            'venmo': 'Venmo',
                            'zelle': 'Zelle',
                            'paypal': 'PayPal',
                            'cash': 'Cash',
                            'store_credit': 'Store Credit',
                            'trade': 'Trade-In'
                          },
                          value: checkout.paymentMethod,
                          onChanged: controller.setPayment),
                      _TradeStep(
                          nameController: _tradeNameController,
                          valueController: _tradeValueController,
                          checkout: checkout,
                          controller: controller),
                      _CouponStep(
                          couponController: _couponController,
                          checkout: checkout,
                          controller: controller),
                      _SubmitStep(
                          cart: cart,
                          checkout: checkout,
                          controller: controller,
                          discordController: _discordController),
                    ],
                  ),
                ),
                if (checkout.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(checkout.errorMessage!,
                        style: AppTextStyles.body(color: AppColors.pkmnRed)),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                          child: PkButton(
                              label: 'Back',
                              variant: PkButtonVariant.secondary,
                              onPressed: checkout.step == 0
                                  ? null
                                  : () =>
                                      controller.setStep(checkout.step - 1))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PkButton(
                          label: checkout.step == 6 ? 'Place Order' : 'Next',
                          loading: checkout.submitting,
                          onPressed: checkout.step == 6
                              ? controller.placeOrder
                              : () => controller.setStep(checkout.step + 1),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(7, (index) {
          final active = index <= step;
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              color: active ? AppColors.pkmnBlue : AppColors.pkmnBorder,
            ),
          );
        }),
      ),
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({required this.lines});

  final List<CartLine> lines;

  @override
  Widget build(BuildContext context) {
    final total = lines.fold<double>(0, (sum, line) => sum + line.subtotal);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Review Cart', style: AppTextStyles.heading(size: 22)),
        const SizedBox(height: 12),
        ...lines.map((line) => PkCard(
            child: Text(
                '${line.item.title} x${line.quantity} - \$${line.subtotal.toStringAsFixed(2)}'))),
        const SizedBox(height: 12),
        Text('Subtotal: \$${total.toStringAsFixed(2)}',
            textAlign: TextAlign.end, style: AppTextStyles.heading(size: 18)),
      ],
    );
  }
}

class _ChoiceStep extends StatelessWidget {
  const _ChoiceStep(
      {required this.title,
      required this.options,
      required this.value,
      required this.onChanged});

  final String title;
  final Map<String, String> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(title, style: AppTextStyles.heading(size: 22)),
        const SizedBox(height: 12),
        ...options.entries.map((entry) {
          final selected = value == entry.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => onChanged(entry.key),
              child: PkCard(
                child: Row(
                  children: [
                    Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: selected
                            ? AppColors.pkmnBlue
                            : AppColors.pkmnGrayDark),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(entry.value,
                            style: AppTextStyles.heading(size: 16))),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _TradeStep extends StatelessWidget {
  const _TradeStep(
      {required this.nameController,
      required this.valueController,
      required this.checkout,
      required this.controller});

  final TextEditingController nameController;
  final TextEditingController valueController;
  final CheckoutState checkout;
  final CheckoutController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Trade Cards', style: AppTextStyles.heading(size: 22)),
        const SizedBox(height: 12),
        PkInput(controller: nameController, label: 'Card Name'),
        const SizedBox(height: 10),
        PkInput(
            controller: valueController,
            label: 'Estimated Value',
            keyboardType: TextInputType.number),
        const SizedBox(height: 10),
        PkButton(
          label: 'Add Trade Card',
          variant: PkButtonVariant.secondary,
          onPressed: () {
            final value = double.tryParse(valueController.text) ?? 0;
            if (nameController.text.trim().isEmpty || value <= 0) return;
            controller.addTradeCard(TradeCardEntry(
                cardName: nameController.text.trim(), estimatedValue: value));
            nameController.clear();
            valueController.clear();
          },
        ),
        const SizedBox(height: 12),
        ...checkout.tradeCards.indexed.map((entry) => PkCard(
                child: Row(children: [
              Expanded(
                  child: Text(
                      '${entry.$2.cardName} - \$${entry.$2.estimatedValue.toStringAsFixed(2)}')),
              IconButton(
                  onPressed: () => controller.removeTradeCard(entry.$1),
                  icon: const Icon(Icons.close))
            ]))),
      ],
    );
  }
}

class _CouponStep extends StatelessWidget {
  const _CouponStep(
      {required this.couponController,
      required this.checkout,
      required this.controller});

  final TextEditingController couponController;
  final CheckoutState checkout;
  final CheckoutController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Coupon + Store Credit', style: AppTextStyles.heading(size: 22)),
        const SizedBox(height: 12),
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
          PkCard(
              child: Text(
                  'Discount: \$${checkout.coupon!.computedDiscount.toStringAsFixed(2)}')),
        ],
        SwitchListTile(
          value: checkout.useStoreCredit,
          onChanged: controller.setUseStoreCredit,
          title: const Text('Use store credit wallet if available'),
        ),
      ],
    );
  }
}

class _SubmitStep extends StatelessWidget {
  const _SubmitStep(
      {required this.cart,
      required this.checkout,
      required this.controller,
      required this.discordController});

  final CartState cart;
  final CheckoutState checkout;
  final CheckoutController controller;
  final TextEditingController discordController;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Review + Submit', style: AppTextStyles.heading(size: 22)),
        const SizedBox(height: 12),
        PkInput(
            controller: discordController,
            label: 'Discord Handle',
            onChanged: controller.setDiscordHandle),
        const SizedBox(height: 12),
        PkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Items: ${cart.totalQuantity}', style: AppTextStyles.body()),
              Text('Payment: ${checkout.paymentMethod}',
                  style: AppTextStyles.body()),
              Text('Delivery: ${checkout.deliveryMethod}',
                  style: AppTextStyles.body()),
              Text('Subtotal: \$${cart.subtotal.toStringAsFixed(2)}',
                  style: AppTextStyles.heading(size: 18)),
            ],
          ),
        ),
      ],
    );
  }
}
