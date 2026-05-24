import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/api_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pk_button.dart';
import '../providers/cart_controller.dart';

class CartQuantityControl extends ConsumerWidget {
  const CartQuantityControl({
    required this.item,
    this.compact = false,
    this.expand = true,
    super.key,
  });

  final ProductItem item;
  final bool compact;
  final bool expand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quantity = ref.watch(cartControllerProvider).quantityFor(item);
    final controller = ref.read(cartControllerProvider.notifier);

    if (quantity <= 0) {
      return PkButton(
        label: item.inStock ? 'Add to Cart' : 'Sold Out',
        variant:
            item.inStock ? PkButtonVariant.primary : PkButtonVariant.secondary,
        expand: expand,
        onPressed: item.inStock
            ? () async {
                final result = await controller.add(item);
                if (context.mounted && result == CartChangeResult.limited) {
                  _showLimitMessage(context);
                }
              }
            : null,
      );
    }

    return SizedBox(
      width: expand ? double.infinity : (compact ? 132 : 160),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.pkmnBlue, width: 1.5),
          borderRadius: AppDecorations.controlRadius,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 10,
            vertical: compact ? 4 : 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _QuantityIconButton(
                icon: Icons.remove,
                onPressed: () => controller.setQuantity(item, quantity - 1),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 34),
                child: Text(
                  '$quantity',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading(size: compact ? 16 : 18),
                ),
              ),
              _QuantityIconButton(
                icon: Icons.add,
                onPressed: () async {
                  final result =
                      await controller.setQuantity(item, quantity + 1);
                  if (context.mounted && result == CartChangeResult.limited) {
                    _showLimitMessage(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLimitMessage(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(CartController.limitMessage)),
    );
  }
}

class _QuantityIconButton extends StatelessWidget {
  const _QuantityIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 36,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: onPressed,
        icon: Icon(icon, size: 22, color: AppColors.pkmnBlueDark),
      ),
    );
  }
}
