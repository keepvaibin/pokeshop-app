import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/cart/presentation/providers/cart_controller.dart';
import 'pk_badge.dart';

class CartIconButton extends ConsumerWidget {
  const CartIconButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartControllerProvider).totalQuantity;
    final location = GoRouterState.of(context).matchedLocation;
    final cartPath = location.startsWith('/admin') ? '/admin/cart' : '/cart';
    return IconButton(
      tooltip: 'Cart',
      onPressed: () => context.push(cartPath),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.shopping_bag_outlined),
          if (count > 0)
            Positioned(right: -10, top: -8, child: PkBadge(count: count)),
        ],
      ),
    );
  }
}
