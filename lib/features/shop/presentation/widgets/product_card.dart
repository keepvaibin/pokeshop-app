import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/api_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pk_card.dart';
import '../../../../core/widgets/pk_network_image.dart';
import '../../../../core/widgets/pk_pill.dart';
import '../../../cart/presentation/widgets/cart_quantity_control.dart';

class ProductCard extends ConsumerWidget {
  const ProductCard({required this.item, this.compact = false, super.key});

  final ProductItem item;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RepaintBoundary(
      child: InkWell(
        onTap: () {
          final location = GoRouterState.of(context).matchedLocation;
          final prefix = location.startsWith('/admin') ? '/admin' : '';
          context.push('$prefix/product/${item.slug}');
        },
        child: PkCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: PkNetworkImage(
                  imageUrl: item.imageUrl,
                  semanticLabel: item.title,
                  padding: const EdgeInsets.all(14),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.category.isNotEmpty)
                      PkPill(label: item.category, color: AppColors.pkmnBlue),
                    if (item.category.isNotEmpty) const SizedBox(height: 8),
                    Text(item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.heading(size: compact ? 14 : 16)),
                    const SizedBox(height: 6),
                    Text('\$${item.price.toStringAsFixed(2)}',
                        style: AppTextStyles.heading(
                            size: 16, color: AppColors.pkmnBlueDark)),
                    const SizedBox(height: 10),
                    CartQuantityControl(item: item, compact: compact),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
