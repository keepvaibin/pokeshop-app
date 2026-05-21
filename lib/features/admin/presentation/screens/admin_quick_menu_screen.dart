import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pk_card.dart';
import '../../../../core/widgets/pk_pill.dart';

class AdminQuickMenuScreen extends StatelessWidget {
  const AdminQuickMenuScreen({super.key});

  static const List<_AdminMenuItem> _items = [
    _AdminMenuItem(
      label: 'Point of Sale',
      description: 'Create in-person orders',
      icon: Icons.point_of_sale_outlined,
      path: '/admin/pos',
      ready: true,
    ),
    _AdminMenuItem(
      label: 'Users',
      description: 'Profiles, wallet, restrictions',
      icon: Icons.people_alt_outlined,
      path: '/admin/users',
      ready: true,
    ),
    _AdminMenuItem(
      label: 'Metrics',
      description: 'Sales and fulfillment reporting',
      icon: Icons.analytics_outlined,
      path: '/admin/metrics',
      ready: true,
    ),
    _AdminMenuItem(
      label: 'Dispatch',
      description: 'Fulfillment, trades, overdue',
      icon: Icons.local_shipping_outlined,
      path: '/admin/dispatch',
      ready: true,
    ),
    _AdminMenuItem(
      label: 'Inventory',
      description: 'Edit storefront items',
      icon: Icons.inventory_2_outlined,
      path: '/admin/inventory',
      ready: true,
    ),
    _AdminMenuItem(
      label: 'Cards',
      description: 'TCG card catalog and sync jobs',
      icon: Icons.style_outlined,
      path: '/admin/cards',
      ready: true,
    ),
    _AdminMenuItem(
      label: 'Categories',
      description: 'Categories and subcategories',
      icon: Icons.category_outlined,
      path: '/admin/categories',
      ready: true,
    ),
    _AdminMenuItem(
      label: 'Promo Banners',
      description: 'Homepage and sale banners',
      icon: Icons.campaign_outlined,
      path: '/admin/promos',
      ready: true,
    ),
    _AdminMenuItem(
      label: 'Campaigns',
      description: 'Hero posts, CTAs, and campaign copy',
      icon: Icons.article_outlined,
      path: '/admin/campaigns',
      ready: true,
    ),
    _AdminMenuItem(
      label: 'Wanted List',
      description: 'Cards the shop wants',
      icon: Icons.saved_search_outlined,
      path: '/admin/wanted',
      ready: true,
    ),
    _AdminMenuItem(
      label: 'Order History',
      description: 'All order records and actions',
      icon: Icons.receipt_long_outlined,
      path: '/admin/orders',
      ready: true,
    ),
    _AdminMenuItem(
      label: 'Trade History',
      description: 'Customer trade requests',
      icon: Icons.handshake_outlined,
      path: '/admin/trade-ins',
      ready: true,
    ),
    _AdminMenuItem(
      label: 'Coupons',
      description: 'Promo codes and restrictions',
      icon: Icons.confirmation_number_outlined,
      path: '/admin/coupons',
      ready: true,
    ),
    _AdminMenuItem(
      label: 'Access Codes',
      description: 'Registration access control',
      icon: Icons.key_outlined,
      path: '/admin/access-codes',
      ready: true,
    ),
    _AdminMenuItem(
      label: 'Strikes',
      description: 'Account warnings and limits',
      icon: Icons.report_gmailerrorred_outlined,
      path: '/admin/strikes',
      ready: true,
    ),
    _AdminMenuItem(
      label: 'Settings',
      description: 'Store, profile, and payments',
      icon: Icons.tune_outlined,
      path: '/admin/settings',
      ready: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quick Menu')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length + 1,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Text('Admin tools', style: AppTextStyles.heading(size: 24));
          }
          return _AdminMenuTile(item: _items[index - 1]);
        },
      ),
    );
  }
}

class _AdminMenuTile extends StatelessWidget {
  const _AdminMenuTile({required this.item});

  final _AdminMenuItem item;

  @override
  Widget build(BuildContext context) {
    final enabled = item.ready && item.path != null;
    return InkWell(
      onTap: enabled ? () => context.push(item.path!) : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.62,
        child: PkCard(
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: enabled ? AppColors.pkmnBlueLight : AppColors.pkmnBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.icon,
                  color: enabled ? AppColors.pkmnBlue : AppColors.pkmnGrayDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.label, style: AppTextStyles.heading(size: 16)),
                    const SizedBox(height: 3),
                    Text(item.description, style: AppTextStyles.body(size: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (enabled)
                const Icon(Icons.chevron_right, color: AppColors.pkmnGrayDark)
              else
                const PkPill(label: 'Next'),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminMenuItem {
  const _AdminMenuItem({
    required this.label,
    required this.description,
    required this.icon,
    this.path,
    this.ready = false,
  });

  final String label;
  final String description;
  final IconData icon;
  final String? path;
  final bool ready;
}
