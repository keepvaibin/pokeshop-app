import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/json_helpers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pk_button.dart';
import '../../../../core/widgets/pk_card.dart';
import '../../data/admin_repository.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(adminSnapshotProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: snapshot.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            PkCard(child: Text('$error')),
            const SizedBox(height: 12),
            _AdminActions(),
          ],
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminSnapshotProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Admin Dashboard', style: AppTextStyles.heading(size: 24)),
              const SizedBox(height: 4),
              Text('Live operations, dispatch queue, and storefront shortcuts.',
                  style: AppTextStyles.body()),
              const SizedBox(height: 12),
              _KpiGrid(data: data.dashboard),
              const SizedBox(height: 20),
              _DispatchQueue(data: data.dashboard),
              const SizedBox(height: 20),
              _Promotions(data: data.dashboard),
              const SizedBox(height: 20),
              _AdminActions(),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final kpis = asMap(data['kpis']);
    final cards = [
      _Kpi(
          label: 'Pending Dispatches',
          value: _number(kpis, 'pending_dispatches'),
          icon: Icons.local_shipping,
          color: AppColors.pkmnYellowDark,
          path: '/admin/dispatch'),
      _Kpi(
          label: 'Pending Today',
          value: _number(kpis, 'pending_dispatches_today'),
          icon: Icons.today,
          color: AppColors.pkmnBlue,
          path: '/admin/dispatch'),
      _Kpi(
          label: "Today's Orders",
          value: _number(kpis, 'todays_orders'),
          icon: Icons.shopping_bag,
          color: AppColors.pkmnBlueDark,
          path: '/admin/orders'),
      _Kpi(
          label: "Today's Revenue",
          value: '\$${asDouble(kpis['todays_revenue']).toStringAsFixed(2)}',
          icon: Icons.trending_up,
          color: Colors.green,
          path: '/admin/orders'),
      _Kpi(
          label: 'Low Stock',
          value: _number(kpis, 'low_stock'),
          icon: Icons.warning_amber,
          color: Colors.orange,
          path: '/admin/menu'),
      _Kpi(
          label: 'Out of Stock',
          value: _number(kpis, 'out_of_stock'),
          icon: Icons.error_outline,
          color: AppColors.pkmnRed,
          path: '/admin/menu'),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.55,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) => cards[index],
    );
  }

  String _number(Map<String, dynamic> source, String key) =>
      '${asInt(source[key])}';
}

class _Kpi extends StatelessWidget {
  const _Kpi(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color,
      required this.path});

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String path;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(path),
      child: PkCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const Spacer(),
                const Icon(Icons.chevron_right,
                    color: AppColors.pkmnGrayDark, size: 18),
              ],
            ),
            Text(label.toUpperCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label(color: AppColors.pkmnGrayDark)
                    .copyWith(fontSize: 10)),
            Text(value, style: AppTextStyles.heading(size: 24, color: color)),
          ],
        ),
      ),
    );
  }
}

class _DispatchQueue extends StatelessWidget {
  const _DispatchQueue({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final rows = asMapList(data['dispatch_queue']);
    return PkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text('Dispatch Queue',
                      style: AppTextStyles.heading(size: 18))),
              TextButton(
                  onPressed: () => context.go('/admin/dispatch'),
                  child: const Text('View all')),
            ],
          ),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            Text('No pending dispatches.',
                style: AppTextStyles.body(color: AppColors.pkmnGrayDark))
          else
            ...rows.map((row) => _DispatchRow(row: row)),
        ],
      ),
    );
  }
}

class _DispatchRow extends StatelessWidget {
  const _DispatchRow({required this.row});

  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final orderId = asString(row['order_id']);
    return InkWell(
      onTap:
          orderId.isEmpty ? null : () => context.push('/admin/orders/$orderId'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.receipt_long, size: 18, color: AppColors.pkmnBlue),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(asString(row['items_summary'], fallback: orderId),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.heading(size: 14)),
                  const SizedBox(height: 2),
                  Text(asString(row['customer_email']),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body(
                          size: 12, color: AppColors.pkmnGrayDark)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(asString(row['status']).replaceAll('_', ' '),
                style: AppTextStyles.label(color: AppColors.pkmnBlue)),
          ],
        ),
      ),
    );
  }
}

class _Promotions extends StatelessWidget {
  const _Promotions({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final promotions = asMap(data['promotions']);
    return Row(
      children: [
        Expanded(
            child: _PromoCard(
                label: 'Promo Banners',
                value: asInt(promotions['active_banners']))),
        const SizedBox(width: 12),
        Expanded(
            child: _PromoCard(
                label: 'Active Coupons',
                value: asInt(promotions['active_coupons']))),
      ],
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return PkCard(
      child: Column(
        children: [
          Text('$value',
              style:
                  AppTextStyles.heading(size: 24, color: AppColors.pkmnBlue)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: AppTextStyles.label(color: AppColors.pkmnGrayDark)),
        ],
      ),
    );
  }
}

class _AdminActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Quick Actions', style: AppTextStyles.heading(size: 18)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              PkButton(
                  label: 'Orders',
                  icon: const Icon(Icons.receipt_long),
                  onPressed: () => context.go('/admin/menu'),
                  variant: PkButtonVariant.secondary),
              PkButton(
                  label: 'Shop View',
                  icon: const Icon(Icons.storefront),
                  onPressed: () => context.go('/admin/shop'),
                  variant: PkButtonVariant.secondary),
              PkButton(
                  label: 'Trade-Ins',
                  icon: const Icon(Icons.style),
                  onPressed: () => context.go('/admin/dispatch'),
                  variant: PkButtonVariant.secondary),
              PkButton(
                  label: 'Settings',
                  icon: const Icon(Icons.tune),
                  onPressed: () => context.go('/admin/settings'),
                  variant: PkButtonVariant.secondary),
            ],
          ),
        ],
      ),
    );
  }
}
