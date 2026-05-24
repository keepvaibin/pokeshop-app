import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/api_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pk_button.dart';
import '../../../../core/widgets/pk_card.dart';
import '../../../../core/widgets/pk_network_image.dart';
import '../../../shop/data/shop_repository.dart';
import '../providers/cart_controller.dart';
import '../widgets/cart_quantity_control.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartControllerProvider);
    final settings = ref.watch(storeSettingsProvider).valueOrNull;
    final controller = ref.read(cartControllerProvider.notifier);
    final tax =
        TaxDisplay.split(cart.subtotal, settings?.salesTaxRatePercent ?? 9.25);
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: cart.lines.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shopping_bag_outlined,
                        size: 56, color: AppColors.pkmnGrayDark),
                    const SizedBox(height: 12),
                    Text('Your cart is empty.',
                        style: AppTextStyles.heading(size: 20)),
                    const SizedBox(height: 12),
                    PkButton(
                        label: 'Browse Shop',
                        onPressed: () => context.go('/shop')),
                  ],
                ),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth =
                    constraints.maxWidth >= 760 ? 720.0 : double.infinity;
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.lines.length + 1,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == cart.lines.length) {
                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: PkCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Subtotal before tax',
                                        style: AppTextStyles.heading(size: 18)),
                                    Text(formatMoney(tax.preTaxSubtotal),
                                        style: AppTextStyles.heading(
                                            size: 18,
                                            color: AppColors.pkmnBlueDark)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Sales tax',
                                        style: AppTextStyles.body(size: 13)),
                                    Text(formatMoney(tax.salesTax),
                                        style: AppTextStyles.body(size: 13)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Total after tax',
                                        style: AppTextStyles.heading(size: 15)),
                                    Text(formatMoney(cart.subtotal),
                                        style: AppTextStyles.heading(size: 15)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                PkButton(
                                    label: 'Checkout',
                                    onPressed: () {
                                      final location = GoRouterState.of(context)
                                          .matchedLocation;
                                      final checkoutPath =
                                          location.startsWith('/admin')
                                              ? '/admin/checkout'
                                              : '/checkout';
                                      context.push(checkoutPath);
                                    },
                                    expand: true),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    final line = cart.lines[index];
                    return Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: PkCard(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 64,
                                height: 64,
                                child: PkNetworkImage(
                                  imageUrl: line.item.imageUrl,
                                  semanticLabel: line.item.title,
                                  padding: const EdgeInsets.all(6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(line.item.title,
                                        style: AppTextStyles.heading(size: 13),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 3),
                                    Text('${line.item.customerPriceLabel} each',
                                        style: AppTextStyles.body(size: 12)),
                                    Text(
                                        'Line total: ${formatMoney(line.subtotal)}',
                                        style: AppTextStyles.heading(size: 12)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CartQuantityControl(
                                    item: line.item,
                                    compact: true,
                                    expand: false,
                                  ),
                                  const SizedBox(height: 6),
                                  GestureDetector(
                                    onTap: () => controller.remove(line.item),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.delete_outline,
                                            size: 14, color: AppColors.pkmnRed),
                                        const SizedBox(width: 3),
                                        Text('Remove',
                                            style: AppTextStyles.body(
                                                size: 12,
                                                color: AppColors.pkmnRed)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
