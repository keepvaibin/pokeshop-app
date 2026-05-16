import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pk_card.dart';
import '../../../../core/widgets/pk_network_image.dart';
import '../../../../core/widgets/pk_status_badge.dart';
import '../../data/orders_repository.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(myOrdersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: orders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('$error')),
        data: (items) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(myOrdersProvider),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth =
                  constraints.maxWidth >= 760 ? 720.0 : double.infinity;
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.isEmpty ? 1 : items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (items.isEmpty) {
                    return const PkCard(child: Text('No orders yet.'));
                  }
                  final order = items[index];
                  final firstImage =
                      order.items.isEmpty ? null : order.items.first.imageUrl;
                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: InkWell(
                        onTap: () => context.push('/orders/${order.orderId}'),
                        child: PkCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(
                                    child: Text(order.orderId,
                                        style:
                                            AppTextStyles.heading(size: 16))),
                                PkStatusBadge(status: order.status)
                              ]),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 54,
                                    height: 54,
                                    child: PkNetworkImage(
                                      imageUrl: firstImage,
                                      semanticLabel: order.orderId,
                                      padding: const EdgeInsets.all(6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          order.itemsSummary.isNotEmpty
                                              ? order.itemsSummary
                                              : order.items
                                                  .map((line) =>
                                                      '${line.title} x${line.quantity}')
                                                  .join(', '),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.body(
                                              color: AppColors.pkmnText),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          order.pickupLabel.isEmpty
                                              ? order.deliveryMethod
                                              : order.pickupLabel,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.body(size: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Due: \$${order.netDue.toStringAsFixed(2)}',
                                  style: AppTextStyles.heading(size: 15)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
