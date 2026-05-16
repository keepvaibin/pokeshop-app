import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pk_button.dart';
import '../../../../core/widgets/pk_card.dart';
import '../../../../core/widgets/pk_network_image.dart';
import '../providers/cart_controller.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartControllerProvider);
    final controller = ref.read(cartControllerProvider.notifier);
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
                                    Text('Subtotal',
                                        style: AppTextStyles.heading(size: 18)),
                                    Text(
                                        '\$${cart.subtotal.toStringAsFixed(2)}',
                                        style: AppTextStyles.heading(
                                            size: 18,
                                            color: AppColors.pkmnBlueDark)),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 72,
                                height: 72,
                                child: PkNetworkImage(
                                  imageUrl: line.item.imageUrl,
                                  semanticLabel: line.item.title,
                                  padding: const EdgeInsets.all(8),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(line.item.title,
                                        style: AppTextStyles.heading(size: 16)),
                                    const SizedBox(height: 4),
                                    Text(
                                        '\$${line.item.price.toStringAsFixed(2)} each',
                                        style: AppTextStyles.body(size: 12)),
                                    const SizedBox(height: 6),
                                    Text(
                                        'Line total: \$${line.subtotal.toStringAsFixed(2)}',
                                        style: AppTextStyles.heading(size: 13)),
                                    TextButton.icon(
                                      onPressed: () =>
                                          controller.remove(line.item.id),
                                      icon: const Icon(Icons.delete_outline,
                                          size: 18),
                                      label: const Text('Remove'),
                                      style: TextButton.styleFrom(
                                          foregroundColor: AppColors.pkmnRed),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                  onPressed: () => controller.updateQuantity(
                                      line.item.id, line.quantity - 1),
                                  icon: const Icon(Icons.remove)),
                              Text('${line.quantity}',
                                  style: AppTextStyles.heading(size: 16)),
                              IconButton(
                                  onPressed: line.item.stockQuantity > 0 &&
                                          line.quantity >=
                                              line.item.stockQuantity
                                      ? null
                                      : () => controller.updateQuantity(
                                          line.item.id, line.quantity + 1),
                                  icon: const Icon(Icons.add)),
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
