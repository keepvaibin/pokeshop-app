import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/json_helpers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pk_card.dart';
import '../../data/admin_repository.dart';

class AdminMetricsScreen extends ConsumerStatefulWidget {
  const AdminMetricsScreen({super.key});

  @override
  ConsumerState<AdminMetricsScreen> createState() => _AdminMetricsScreenState();
}

class _AdminMetricsScreenState extends ConsumerState<AdminMetricsScreen> {
  String _range = '30';
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metrics'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && !snapshot.hasData) {
            return Center(child: Text('${snapshot.error}'));
          }
          final data = snapshot.data ?? const <String, dynamic>{};
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Sales reporting', style: AppTextStyles.heading(size: 24)),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: '7', label: Text('7d')),
                    ButtonSegment(value: '30', label: Text('30d')),
                    ButtonSegment(value: '90', label: Text('90d')),
                    ButtonSegment(value: 'all', label: Text('All')),
                  ],
                  selected: {_range},
                  onSelectionChanged: (value) {
                    setState(() => _range = value.first);
                    _refresh();
                  },
                ),
                const SizedBox(height: 16),
                _SummaryGrid(summary: asMap(data['summary'])),
                const SizedBox(height: 16),
                _DailyChart(rows: asMapList(data['daily'])),
                const SizedBox(height: 16),
                _SectionList(
                  title: 'Top Products',
                  rows: asMapList(data['top_products']),
                  titleKey: 'item_title',
                  valueBuilder: (row) =>
                      '${asInt(row['quantity'])} sold • ${_money(row['revenue'])}',
                ),
                const SizedBox(height: 12),
                _SectionList(
                  title: 'Category Revenue',
                  rows: asMapList(data['category_revenue']),
                  titleKey: 'category',
                  valueBuilder: (row) => _money(row['revenue']),
                ),
                const SizedBox(height: 12),
                _SectionList(
                  title: 'Payment Methods',
                  rows: asMapList(data['payment_methods']),
                  titleKey: 'payment_method',
                  valueBuilder: (row) =>
                      '${asInt(row['orders'])} orders • ${_money(row['revenue'])}',
                ),
                const SizedBox(height: 12),
                _SectionList(
                  title: 'Status Counts',
                  rows: asMapList(data['status_counts']),
                  titleKey: 'status',
                  valueBuilder: (row) => '${asInt(row['orders'])} orders',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _load() {
    return ref.read(adminRepositoryProvider).loadMetrics(_range);
  }

  void _refresh() {
    setState(() => _future = _load());
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});

  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      ('Revenue', _money(summary['revenue']), AppColors.pkmnBlue),
      ('Orders', '${asInt(summary['orders'])}', AppColors.pkmnText),
      ('AOV', _money(summary['average_order_value']), AppColors.pkmnYellowDark),
      (
        'Customers',
        '${asInt(summary['active_customers'])}',
        AppColors.pkmnBlueDark
      ),
      (
        'Fulfilled',
        '${asInt(summary['fulfilled_orders'])}',
        AppColors.pkmnBlue
      ),
      (
        'Fulfillment',
        '${asDouble(summary['fulfillment_rate']).toStringAsFixed(1)}%',
        AppColors.pkmnBlueDark
      ),
      ('Cancelled', '${asInt(summary['cancelled_orders'])}', AppColors.pkmnRed),
      (
        'Pending',
        '${asInt(summary['pending_dispatches'])}',
        AppColors.pkmnYellowDark
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 740 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tiles.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.75,
          ),
          itemBuilder: (context, index) {
            final tile = tiles[index];
            return PkCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(tile.$1.toUpperCase(),
                      style:
                          AppTextStyles.label(color: AppColors.pkmnGrayDark)),
                  const SizedBox(height: 6),
                  FittedBox(
                      child: Text(tile.$2,
                          style:
                              AppTextStyles.heading(size: 22, color: tile.$3))),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _DailyChart extends StatelessWidget {
  const _DailyChart({required this.rows});

  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    final recent = rows.length > 14 ? rows.sublist(rows.length - 14) : rows;
    final maxRevenue = recent.fold<double>(0, (max, row) {
      final revenue = asDouble(row['revenue']);
      return revenue > max ? revenue : max;
    });
    return PkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daily Revenue', style: AppTextStyles.heading(size: 18)),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            const Text('No orders in this range.')
          else
            SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final row in recent)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('${asInt(row['orders'])}',
                                style: AppTextStyles.body(size: 10)),
                            const SizedBox(height: 4),
                            Flexible(
                              child: FractionallySizedBox(
                                heightFactor: maxRevenue <= 0
                                    ? 0.03
                                    : (asDouble(row['revenue']) / maxRevenue)
                                        .clamp(0.03, 1),
                                alignment: Alignment.bottomCenter,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: AppColors.pkmnBlue,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const SizedBox(width: double.infinity),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(_shortDate(row['date']),
                                style: AppTextStyles.body(size: 9),
                                textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _shortDate(Object? value) {
    final parsed = DateTime.tryParse(asString(value));
    if (parsed == null) return '';
    return DateFormat('M/d').format(parsed);
  }
}

class _SectionList extends StatelessWidget {
  const _SectionList(
      {required this.title,
      required this.rows,
      required this.titleKey,
      required this.valueBuilder});

  final String title;
  final List<Map<String, dynamic>> rows;
  final String titleKey;
  final String Function(Map<String, dynamic> row) valueBuilder;

  @override
  Widget build(BuildContext context) {
    return PkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.heading(size: 18)),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            const Text('No data yet.')
          else
            ...rows.map((row) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(
                              asString(row[titleKey]).replaceAll('_', ' '),
                              style: AppTextStyles.body())),
                      Text(valueBuilder(row),
                          style: AppTextStyles.heading(size: 13)),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

String _money(Object? value) => '\$${asDouble(value).toStringAsFixed(2)}';
