import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/api_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pk_button.dart';
import '../../../../core/widgets/pk_card.dart';
import '../../../../core/widgets/pk_status_badge.dart';
import '../../../../core/widgets/pokemon_avatar.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../orders/data/orders_repository.dart';
import '../../../trade_in/data/trade_in_repository.dart';

class MySctcgScreen extends ConsumerWidget {
  const MySctcgScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final orders = ref.watch(myOrdersProvider);
    final wallet = ref.watch(walletProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My SCTCG')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myOrdersProvider);
          ref.invalidate(walletProvider);
          await ref.read(authControllerProvider.notifier).refreshUser();
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth =
                constraints.maxWidth >= 760 ? 720.0 : double.infinity;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PkCard(
                          child: Row(
                            children: [
                              PokemonAvatar(
                                filename: user.pokemonIcon,
                                fallbackText: user.displayName,
                                size: 72,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'Hi ${_friendlyName(user.displayName)}',
                                        style: AppTextStyles.heading(size: 22)),
                                    const SizedBox(height: 4),
                                    Text(user.email,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.body(size: 12)),
                                    const SizedBox(height: 10),
                                    PkButton(
                                      label: 'Profile Settings',
                                      icon: const Icon(
                                          Icons.manage_accounts_outlined),
                                      variant: PkButtonVariant.secondary,
                                      onPressed: () =>
                                          context.push('/settings'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _AccountHealthCard(
                          discordHandle: user.discordHandle,
                          noDiscord: user.noDiscord,
                          strikeCount: user.strikeCount,
                          wallet: wallet,
                        ),
                        const SizedBox(height: 12),
                        const _QuickActions(),
                        const SizedBox(height: 12),
                        _PurchaseHistory(orders: orders),
                      ],
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

  String _friendlyName(String displayName) {
    final value = displayName.trim();
    if (value.isEmpty) return 'there';
    return value.split(RegExp(r'\s+')).first;
  }
}

class _AccountHealthCard extends StatelessWidget {
  const _AccountHealthCard({
    required this.discordHandle,
    required this.noDiscord,
    required this.strikeCount,
    required this.wallet,
  });

  final String discordHandle;
  final bool noDiscord;
  final int strikeCount;
  final AsyncValue<WalletSummary> wallet;

  @override
  Widget build(BuildContext context) {
    return PkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Account', style: AppTextStyles.heading(size: 18)),
          const SizedBox(height: 12),
          _StatusLine(
            icon: Icons.discord_outlined,
            label: 'Discord',
            value: discordHandle.isNotEmpty
                ? discordHandle
                : noDiscord
                    ? 'Skipped'
                    : 'Not connected',
            color: discordHandle.isNotEmpty
                ? AppColors.pkmnBlue
                : AppColors.pkmnYellowDark,
          ),
          const SizedBox(height: 8),
          _StatusLine(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Trade Credit',
            value: wallet.when(
              loading: () => 'Loading',
              error: (error, stackTrace) => 'Unavailable',
              data: (data) => '\$${data.balance.toStringAsFixed(2)}',
            ),
            color: AppColors.pkmnBlueDark,
          ),
          const SizedBox(height: 8),
          _StatusLine(
            icon: Icons.verified_user_outlined,
            label: 'Standing',
            value: strikeCount == 0
                ? 'Clear'
                : '$strikeCount strike${strikeCount == 1 ? '' : 's'}',
            color: strikeCount == 0 ? AppColors.pkmnBlue : AppColors.pkmnRed,
          ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: AppTextStyles.body(size: 13))),
        Text(value, style: AppTextStyles.heading(size: 14, color: color)),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.receipt_long_outlined,
            label: 'Orders',
            onTap: () => context.go('/orders'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionCard(
            icon: Icons.style_outlined,
            label: 'Trade In',
            onTap: () => context.go('/trade-in'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionCard(
            icon: Icons.storefront_outlined,
            label: 'Shop',
            onTap: () => context.go('/shop'),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: PkCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Column(
          children: [
            Icon(icon, color: AppColors.pkmnBlue),
            const SizedBox(height: 6),
            Text(label,
                style: AppTextStyles.label(), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _PurchaseHistory extends StatelessWidget {
  const _PurchaseHistory({required this.orders});

  final AsyncValue<List<OrderSummary>> orders;

  @override
  Widget build(BuildContext context) {
    return PkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Purchase History',
                    style: AppTextStyles.heading(size: 18)),
              ),
              TextButton(
                onPressed: () => context.go('/orders'),
                child: const Text('View all'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          orders.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => Text('Orders unavailable',
                style: AppTextStyles.body(color: AppColors.pkmnRed)),
            data: (items) {
              if (items.isEmpty) {
                return Text('No orders yet. Your purchases will show up here.',
                    style: AppTextStyles.body());
              }
              return Column(
                children: [
                  for (final order in items.take(3))
                    _OrderPreview(order: order),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OrderPreview extends StatelessWidget {
  const _OrderPreview({required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/orders/${order.orderId}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.orderId, style: AppTextStyles.heading(size: 14)),
                  const SizedBox(height: 2),
                  Text(
                    order.itemsSummary.isNotEmpty
                        ? order.itemsSummary
                        : order.items.map((line) => line.title).join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body(size: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PkStatusBadge(status: order.status),
          ],
        ),
      ),
    );
  }
}
