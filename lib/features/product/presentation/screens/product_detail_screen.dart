import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pk_button.dart';
import '../../../../core/widgets/cart_icon_button.dart';
import '../../../../core/widgets/pk_card.dart';
import '../../../../core/widgets/pk_network_image.dart';
import '../../../cart/presentation/providers/cart_controller.dart';
import '../../../shop/data/shop_repository.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({required this.slug, super.key});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(productProvider(slug));
    return Scaffold(
      appBar: AppBar(
          title: const Text('Product'), actions: const [CartIconButton()]),
      body: product.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('$error')),
        data: (item) => LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth =
                constraints.maxWidth >= 760 ? 720.0 : double.infinity;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: PkCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 360,
                            child: PkNetworkImage(
                              imageUrl: item.imageUrl,
                              semanticLabel: item.title,
                              padding: const EdgeInsets.all(20),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.title,
                                    style: AppTextStyles.heading(size: 26)),
                                const SizedBox(height: 8),
                                Text('\$${item.price.toStringAsFixed(2)}',
                                    style: AppTextStyles.heading(
                                        size: 22,
                                        color: AppColors.pkmnBlueDark)),
                                const SizedBox(height: 12),
                                Text(
                                    item.inStock
                                        ? '${item.stockQuantity} available'
                                        : 'Sold out',
                                    style: AppTextStyles.label(
                                        color: item.inStock
                                            ? AppColors.pkmnBlue
                                            : AppColors.pkmnRed)),
                                const SizedBox(height: 16),
                                PkButton(
                                    label: item.inStock
                                        ? 'Add to Cart'
                                        : 'Sold Out',
                                    onPressed: item.inStock
                                        ? () async {
                                            await ref
                                                .read(cartControllerProvider
                                                    .notifier)
                                                .add(item);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(const SnackBar(
                                                      content: Text(
                                                          'Added to cart')));
                                            }
                                          }
                                        : null,
                                    expand: true),
                                if (item.description.trim().isNotEmpty) ...[
                                  const SizedBox(height: 18),
                                  Html(data: item.description),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
