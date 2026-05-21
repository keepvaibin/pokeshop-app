import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/models/api_models.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/json_helpers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pk_button.dart';
import '../../../../core/widgets/pk_card.dart';
import '../../../../core/widgets/pk_network_image.dart';
import '../../data/admin_repository.dart';

enum AdminFieldType {
  text,
  multiline,
  number,
  money,
  boolean,
  select,
  dateTime
}

class AdminDisplayField {
  const AdminDisplayField(this.key, this.label, {this.money = false});

  final String key;
  final String label;
  final bool money;
}

class AdminFormFieldConfig {
  const AdminFormFieldConfig({
    required this.key,
    required this.label,
    this.type = AdminFieldType.text,
    this.required = false,
    this.readOnlyWhenEditing = false,
    this.uppercase = false,
    this.options = const [],
    this.defaultValue,
    this.helperText,
  });

  final String key;
  final String label;
  final AdminFieldType type;
  final bool required;
  final bool readOnlyWhenEditing;
  final bool uppercase;
  final List<String> options;
  final Object? defaultValue;
  final String? helperText;
}

class AdminResourceConfig {
  const AdminResourceConfig({
    required this.title,
    required this.description,
    required this.listPath,
    required this.titleKeys,
    required this.displayFields,
    required this.formFields,
    this.savePath,
    this.detailKey = 'id',
    this.defaultQuery = const {},
    this.searchParameter,
    this.searchFields = const [],
    this.canCreate = true,
    this.canEdit = true,
    this.canDelete = true,
    this.usePut = false,
    this.gridMode = false,
    this.supportsImageUpload = false,
    this.gridImageKey,
    this.gridPriceKey,
    this.gridStockKey,
  });

  final String title;
  final String description;
  final String listPath;
  final String? savePath;
  final String detailKey;
  final Map<String, dynamic> defaultQuery;
  final String? searchParameter;
  final List<String> titleKeys;
  final List<String> searchFields;
  final List<AdminDisplayField> displayFields;
  final List<AdminFormFieldConfig> formFields;
  final bool canCreate;
  final bool canEdit;
  final bool canDelete;
  final bool usePut;
  // Grid view options
  final bool gridMode;
  final bool supportsImageUpload;
  final String? gridImageKey;
  final String? gridPriceKey;
  final String? gridStockKey;

  String get writePath => savePath ?? listPath;

  String titleFor(Map<String, dynamic> item) {
    for (final key in titleKeys) {
      final value = asString(item[key]).trim();
      if (value.isNotEmpty) return value;
    }
    final id = asString(item[detailKey]).trim();
    return id.isEmpty ? title : '$title #$id';
  }

  Object detailValue(Map<String, dynamic> item) =>
      item[detailKey] ?? item['id'];
}

abstract final class AdminResourceConfigs {
  static const inventory = AdminResourceConfig(
    title: 'Inventory',
    description: 'Storefront products, stock, prices, limits, release data.',
    listPath: ApiEndpoints.items,
    detailKey: 'slug',
    searchParameter: 'q',
    titleKeys: ['title', 'name'],
    searchFields: ['title', 'description', 'tcg_set_name', 'rarity'],
    gridMode: true,
    supportsImageUpload: true,
    gridImageKey: 'image_url',
    gridPriceKey: 'price',
    gridStockKey: 'stock',
    displayFields: [
      AdminDisplayField('price', 'Price', money: true),
      AdminDisplayField('stock', 'Stock'),
      AdminDisplayField('category_slug', 'Category'),
      AdminDisplayField('availability_status', 'Status'),
    ],
    formFields: [
      AdminFormFieldConfig(key: 'title', label: 'Title', required: true),
      AdminFormFieldConfig(
          key: 'description',
          label: 'Description',
          type: AdminFieldType.multiline),
      AdminFormFieldConfig(
          key: 'short_description', label: 'Short Description'),
      AdminFormFieldConfig(
          key: 'price',
          label: 'Price',
          type: AdminFieldType.money,
          required: true),
      AdminFormFieldConfig(
          key: 'stock',
          label: 'Stock',
          type: AdminFieldType.number,
          required: true),
      AdminFormFieldConfig(key: 'image_path', label: 'Image URL or Path'),
      AdminFormFieldConfig(
          key: 'category', label: 'Category ID', type: AdminFieldType.number),
      AdminFormFieldConfig(
          key: 'subcategory',
          label: 'Subcategory ID',
          type: AdminFieldType.number),
      AdminFormFieldConfig(
          key: 'max_per_user',
          label: 'Per Order Limit',
          type: AdminFieldType.number),
      AdminFormFieldConfig(
          key: 'max_per_week',
          label: 'Weekly Limit',
          type: AdminFieldType.number),
      AdminFormFieldConfig(
          key: 'max_total_per_user',
          label: 'Lifetime Limit',
          type: AdminFieldType.number),
      AdminFormFieldConfig(key: 'tcg_set_name', label: 'TCG Set'),
      AdminFormFieldConfig(key: 'rarity', label: 'Rarity'),
      AdminFormFieldConfig(key: 'card_number', label: 'Card Number'),
      AdminFormFieldConfig(
          key: 'regulation_mark', label: 'Regulation Mark', uppercase: true),
      AdminFormFieldConfig(
          key: 'is_active',
          label: 'Active',
          type: AdminFieldType.boolean,
          defaultValue: true),
      AdminFormFieldConfig(
          key: 'show_when_out_of_stock',
          label: 'Show When Out of Stock',
          type: AdminFieldType.boolean),
      AdminFormFieldConfig(
          key: 'preview_before_release',
          label: 'Preview Before Release',
          type: AdminFieldType.boolean),
      AdminFormFieldConfig(
          key: 'published_at',
          label: 'Publish Date',
          type: AdminFieldType.dateTime,
          helperText: 'Leave blank to publish immediately when saving'),
    ],
  );

  static const cards = AdminResourceConfig(
    title: 'Cards',
    description:
        'TCG card metadata, stock state, legality, and catalog cleanup.',
    listPath: ApiEndpoints.adminCards,
    savePath: ApiEndpoints.items,
    detailKey: 'slug',
    defaultQuery: {'page_size': 60, 'sort': 'missing-first'},
    searchParameter: 'q',
    canCreate: false,
    canDelete: false,
    titleKeys: ['title', 'name'],
    searchFields: ['title', 'tcg_set_name', 'card_number', 'api_id'],
    displayFields: [
      AdminDisplayField('stock', 'Stock'),
      AdminDisplayField('tcg_set_name', 'Set'),
      AdminDisplayField('card_number', 'No.'),
      AdminDisplayField('regulation_mark', 'Reg'),
      AdminDisplayField('standard_legal', 'Standard'),
    ],
    formFields: [
      AdminFormFieldConfig(
          key: 'price', label: 'Price', type: AdminFieldType.money),
      AdminFormFieldConfig(
          key: 'stock', label: 'Stock', type: AdminFieldType.number),
      AdminFormFieldConfig(
          key: 'is_active', label: 'Active', type: AdminFieldType.boolean),
      AdminFormFieldConfig(
          key: 'show_when_out_of_stock',
          label: 'Show When Out of Stock',
          type: AdminFieldType.boolean),
      AdminFormFieldConfig(key: 'tcg_set_name', label: 'Set'),
      AdminFormFieldConfig(key: 'card_number', label: 'Card Number'),
      AdminFormFieldConfig(key: 'api_id', label: 'API ID'),
      AdminFormFieldConfig(key: 'rarity', label: 'Printed Rarity'),
      AdminFormFieldConfig(key: 'tcg_supertype', label: 'Supertype'),
      AdminFormFieldConfig(key: 'tcg_type', label: 'Type'),
      AdminFormFieldConfig(key: 'tcg_stage', label: 'Stage'),
      AdminFormFieldConfig(key: 'tcg_subtypes', label: 'Traits'),
      AdminFormFieldConfig(
          key: 'tcg_hp', label: 'HP', type: AdminFieldType.number),
      AdminFormFieldConfig(
          key: 'regulation_mark', label: 'Regulation Mark', uppercase: true),
      AdminFormFieldConfig(
          key: 'standard_legal',
          label: 'Standard Legal',
          type: AdminFieldType.boolean),
      AdminFormFieldConfig(key: 'tcg_artist', label: 'Artist'),
      AdminFormFieldConfig(key: 'tcg_set_release_date', label: 'Release Date'),
    ],
  );

  static const categories = AdminResourceConfig(
    title: 'Categories',
    description: 'Top-level storefront collections and visibility.',
    listPath: ApiEndpoints.categories,
    detailKey: 'slug',
    titleKeys: ['name'],
    searchFields: ['name', 'slug'],
    displayFields: [
      AdminDisplayField('slug', 'Slug'),
      AdminDisplayField('is_active', 'Active'),
      AdminDisplayField('is_core', 'Core'),
    ],
    formFields: [
      AdminFormFieldConfig(key: 'name', label: 'Name', required: true),
      AdminFormFieldConfig(key: 'image_url', label: 'Image URL'),
      AdminFormFieldConfig(
          key: 'is_active',
          label: 'Active',
          type: AdminFieldType.boolean,
          defaultValue: true),
    ],
  );

  static const subcategories = AdminResourceConfig(
    title: 'Subcategories',
    description: 'Nested category filters used by storefront product browsing.',
    listPath: ApiEndpoints.subcategories,
    titleKeys: ['name'],
    searchFields: ['name', 'slug'],
    displayFields: [
      AdminDisplayField('category', 'Category ID'),
      AdminDisplayField('slug', 'Slug'),
      AdminDisplayField('is_active', 'Active'),
    ],
    formFields: [
      AdminFormFieldConfig(
          key: 'category',
          label: 'Category ID',
          type: AdminFieldType.number,
          required: true),
      AdminFormFieldConfig(key: 'name', label: 'Name', required: true),
      AdminFormFieldConfig(
          key: 'is_active',
          label: 'Active',
          type: AdminFieldType.boolean,
          defaultValue: true),
    ],
  );

  static const promos = AdminResourceConfig(
    title: 'Promo Banners',
    description: 'Homepage campaign banners, placement, images, and links.',
    listPath: ApiEndpoints.promoBanners,
    titleKeys: ['title'],
    searchFields: ['title', 'subtitle', 'link_url'],
    displayFields: [
      AdminDisplayField('size', 'Size'),
      AdminDisplayField('position_order', 'Order'),
      AdminDisplayField('is_active', 'Active'),
    ],
    formFields: [
      AdminFormFieldConfig(key: 'title', label: 'Title', required: true),
      AdminFormFieldConfig(key: 'subtitle', label: 'Subtitle'),
      AdminFormFieldConfig(key: 'image_url', label: 'Image URL'),
      AdminFormFieldConfig(key: 'link_url', label: 'Link URL', required: true),
      AdminFormFieldConfig(
          key: 'size',
          label: 'Size',
          type: AdminFieldType.select,
          options: ['FULL', 'HALF', 'QUARTER'],
          defaultValue: 'QUARTER'),
      AdminFormFieldConfig(
          key: 'position_order',
          label: 'Position Order',
          type: AdminFieldType.number),
      AdminFormFieldConfig(
          key: 'is_active',
          label: 'Active',
          type: AdminFieldType.boolean,
          defaultValue: true),
    ],
  );

  static const storefrontCampaigns = AdminResourceConfig(
    title: 'Campaigns',
    description:
        'Storefront campaign posts, hero images, CTAs, and rich body HTML.',
    listPath: ApiEndpoints.adminStorefrontCampaigns,
    titleKeys: ['title'],
    searchFields: ['title', 'subtitle', 'slug', 'cta_url'],
    displayFields: [
      AdminDisplayField('slug', 'Slug'),
      AdminDisplayField('is_currently_active', 'Live'),
      AdminDisplayField('is_active', 'Enabled'),
      AdminDisplayField('display_order', 'Order'),
    ],
    formFields: [
      AdminFormFieldConfig(key: 'title', label: 'Title', required: true),
      AdminFormFieldConfig(key: 'subtitle', label: 'Subtitle'),
      AdminFormFieldConfig(
          key: 'product_line',
          label: 'Product Line ID',
          type: AdminFieldType.number,
          helperText: 'Leave blank for the global homepage campaign.'),
      AdminFormFieldConfig(key: 'hero_image_url', label: 'Hero Image URL'),
      AdminFormFieldConfig(
          key: 'body', label: 'Body HTML', type: AdminFieldType.multiline),
      AdminFormFieldConfig(
          key: 'cta_label', label: 'CTA Label', defaultValue: 'Shop Now'),
      AdminFormFieldConfig(key: 'cta_url', label: 'CTA URL'),
      AdminFormFieldConfig(
          key: 'is_active',
          label: 'Enabled',
          type: AdminFieldType.boolean,
          defaultValue: false),
      AdminFormFieldConfig(
          key: 'starts_at', label: 'Starts At', type: AdminFieldType.dateTime),
      AdminFormFieldConfig(
          key: 'ends_at', label: 'Ends At', type: AdminFieldType.dateTime),
      AdminFormFieldConfig(
          key: 'display_order',
          label: 'Display Order',
          type: AdminFieldType.number),
    ],
  );

  static const wanted = AdminResourceConfig(
    title: 'Wanted List',
    description:
        'Cards the shop is actively seeking for buylist and trade-ins.',
    listPath: ApiEndpoints.wantedCards,
    detailKey: 'slug',
    titleKeys: ['name'],
    searchFields: ['name', 'description'],
    displayFields: [
      AdminDisplayField('estimated_value', 'Value', money: true),
      AdminDisplayField('is_active', 'Active'),
    ],
    formFields: [
      AdminFormFieldConfig(key: 'name', label: 'Name', required: true),
      AdminFormFieldConfig(
          key: 'description',
          label: 'Description',
          type: AdminFieldType.multiline),
      AdminFormFieldConfig(
          key: 'estimated_value',
          label: 'Estimated Value',
          type: AdminFieldType.money,
          required: true),
      AdminFormFieldConfig(
          key: 'tcg_product_id',
          label: 'TCG Product ID',
          type: AdminFieldType.number),
      AdminFormFieldConfig(key: 'tcg_sub_type', label: 'TCG Variant'),
      AdminFormFieldConfig(
          key: 'is_active',
          label: 'Active',
          type: AdminFieldType.boolean,
          defaultValue: true),
    ],
  );

  static const coupons = AdminResourceConfig(
    title: 'Coupons',
    description: 'Discount codes, limits, expiry, and payment restrictions.',
    listPath: ApiEndpoints.coupons,
    titleKeys: ['code'],
    searchFields: ['code'],
    displayFields: [
      AdminDisplayField('discount_amount', 'Amount', money: true),
      AdminDisplayField('discount_percent', 'Percent'),
      AdminDisplayField('times_used', 'Used'),
      AdminDisplayField('usage_limit', 'Limit'),
      AdminDisplayField('is_active', 'Active'),
    ],
    formFields: [
      AdminFormFieldConfig(
          key: 'code', label: 'Code', required: true, uppercase: true),
      AdminFormFieldConfig(
          key: 'discount_amount',
          label: 'Flat Discount',
          type: AdminFieldType.money),
      AdminFormFieldConfig(
          key: 'discount_percent',
          label: 'Percent Discount',
          type: AdminFieldType.money),
      AdminFormFieldConfig(
          key: 'usage_limit',
          label: 'Usage Limit',
          type: AdminFieldType.number),
      AdminFormFieldConfig(
          key: 'min_order_total',
          label: 'Minimum Order Total',
          type: AdminFieldType.money),
      AdminFormFieldConfig(
          key: 'expires_at',
          label: 'Expires At',
          type: AdminFieldType.dateTime),
      AdminFormFieldConfig(
          key: 'is_active',
          label: 'Active',
          type: AdminFieldType.boolean,
          defaultValue: true),
      AdminFormFieldConfig(
          key: 'requires_cash_only',
          label: 'Cash Only',
          type: AdminFieldType.boolean),
    ],
  );

  static const accessCodes = AdminResourceConfig(
    title: 'Access Codes',
    description: 'Registration codes for non-UCSC customers.',
    listPath: ApiEndpoints.accessCodes,
    titleKeys: ['code'],
    searchFields: ['code', 'note'],
    displayFields: [
      AdminDisplayField('times_used', 'Used'),
      AdminDisplayField('usage_limit', 'Limit'),
      AdminDisplayField('expires_at', 'Expires'),
      AdminDisplayField('is_active', 'Active'),
    ],
    formFields: [
      AdminFormFieldConfig(
          key: 'code', label: 'Code', required: true, uppercase: true),
      AdminFormFieldConfig(
          key: 'usage_limit',
          label: 'Usage Limit',
          type: AdminFieldType.number,
          defaultValue: 1),
      AdminFormFieldConfig(
          key: 'expires_at',
          label: 'Expires At',
          type: AdminFieldType.dateTime),
      AdminFormFieldConfig(key: 'note', label: 'Internal Note'),
      AdminFormFieldConfig(
          key: 'is_active',
          label: 'Active',
          type: AdminFieldType.boolean,
          defaultValue: true),
    ],
  );
}

class AdminResourceScreen extends StatelessWidget {
  const AdminResourceScreen(
      {required this.config, this.actions = const [], super.key});

  final AdminResourceConfig config;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(config.title), actions: actions),
      body: AdminResourceList(config: config),
    );
  }
}

class AdminTabbedResourceScreen extends StatelessWidget {
  const AdminTabbedResourceScreen({
    required this.title,
    required this.configs,
    super.key,
  });

  final String title;
  final List<AdminResourceConfig> configs;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: configs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          bottom: TabBar(
            isScrollable: configs.length > 2,
            tabs: [for (final config in configs) Tab(text: config.title)],
          ),
        ),
        body: TabBarView(
          children: [
            for (final config in configs) AdminResourceList(config: config)
          ],
        ),
      ),
    );
  }
}

class AdminResourceList extends ConsumerStatefulWidget {
  const AdminResourceList({required this.config, super.key});

  final AdminResourceConfig config;

  @override
  ConsumerState<AdminResourceList> createState() => _AdminResourceListState();
}

class _AdminResourceListState extends ConsumerState<AdminResourceList> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _items = const [];
  bool _loading = true;
  String? _error;
  String _filter = '';

  AdminResourceConfig get config => widget.config;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AdminResourceList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _searchController.clear();
      _filter = '';
      _load();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              PkButton(label: 'Retry', onPressed: _load),
            ],
          ),
        ),
      );
    }

    final visible = _visibleItems();
    if (config.gridMode) {
      return RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _SearchPanel(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        onSubmitted: _onSearchSubmitted,
                        onRefresh: _load,
                      ),
                    ),
                    if (config.canCreate) ...[
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: 'Create',
                        onPressed: _openCreate,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.68,
                ),
                itemCount: visible.length,
                itemBuilder: (context, index) {
                  final item = visible[index];
                  return _GridResourceCard(
                    config: config,
                    item: item,
                    onEdit: config.canEdit ? () => _openEdit(item) : null,
                    onDelete: config.canDelete ? () => _delete(item) : null,
                  );
                },
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: visible.length + 2,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _Header(
                config: config,
                onCreate: config.canCreate ? _openCreate : null);
          }
          if (index == 1) {
            return _SearchPanel(
                controller: _searchController,
                onChanged: _onSearchChanged,
                onSubmitted: _onSearchSubmitted,
                onRefresh: _load);
          }
          final item = visible[index - 2];
          return _ResourceCard(
            config: config,
            item: item,
            onEdit: config.canEdit ? () => _openEdit(item) : null,
            onDelete: config.canDelete ? () => _delete(item) : null,
          );
        },
      ),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final query = Map<String, dynamic>.from(config.defaultQuery);
      if (config.searchParameter != null && _filter.trim().isNotEmpty) {
        query[config.searchParameter!] = _filter.trim();
      }
      final items = await ref.read(adminRepositoryProvider).listResource(
            config.listPath,
            queryParameters: query.isEmpty ? null : query,
          );
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _visibleItems() {
    if (config.searchParameter != null) return _items;
    final query = _filter.trim().toLowerCase();
    if (query.isEmpty) return _items;
    return _items.where((item) {
      final fields =
          config.searchFields.isEmpty ? config.titleKeys : config.searchFields;
      return fields
          .any((key) => asString(item[key]).toLowerCase().contains(query));
    }).toList(growable: false);
  }

  void _onSearchChanged(String value) {
    setState(() => _filter = value);
  }

  void _onSearchSubmitted(String value) {
    setState(() => _filter = value);
    if (config.searchParameter != null) unawaited(_load());
  }

  Future<void> _openCreate() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => AdminResourceEditor(config: config),
    );
    if (saved == true) await _load();
  }

  Future<void> _openEdit(Map<String, dynamic> item) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => AdminResourceEditor(config: config, item: item),
    );
    if (saved == true) await _load();
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${config.titleFor(item)}?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(adminRepositoryProvider)
          .deleteResource(config.writePath, config.detailValue(item));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Deleted.')));
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.config, required this.onCreate});

  final AdminResourceConfig config;
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(config.title, style: AppTextStyles.heading(size: 24)),
              const SizedBox(height: 4),
              Text(config.description, style: AppTextStyles.body(size: 13)),
            ],
          ),
        ),
        if (onCreate != null) ...[
          const SizedBox(width: 12),
          IconButton.filled(
            tooltip: 'Create',
            onPressed: onCreate,
            icon: const Icon(Icons.add),
          ),
        ],
      ],
    );
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel(
      {required this.controller,
      required this.onChanged,
      required this.onSubmitted,
      required this.onRefresh});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return PkCard(
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Search',
              ),
              textInputAction: TextInputAction.search,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Refresh',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard(
      {required this.config, required this.item, this.onEdit, this.onDelete});

  final AdminResourceConfig config;
  final Map<String, dynamic> item;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final active = item.containsKey('is_active')
        ? asBool(item['is_active'], fallback: true)
        : null;
    return PkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: Text(config.titleFor(item),
                      style: AppTextStyles.heading(size: 16))),
              if (active != null)
                _StatusPill(
                    label: active ? 'Active' : 'Inactive', active: active),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final field in config.displayFields)
                _MetaPill(
                    label: field.label,
                    value: _formatValue(item[field.key], money: field.money)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                  '#${asString(item[config.detailKey], fallback: asString(item['id']))}',
                  style: AppTextStyles.body(
                      size: 12, color: AppColors.pkmnGrayDark)),
              const Spacer(),
              if (onEdit != null)
                IconButton(
                  tooltip: 'Edit',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
              if (onDelete != null)
                IconButton(
                  tooltip: 'Delete',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.pkmnRed),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GridResourceCard extends StatelessWidget {
  const _GridResourceCard({
    required this.config,
    required this.item,
    this.onEdit,
    this.onDelete,
  });

  final AdminResourceConfig config;
  final Map<String, dynamic> item;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final title = config.titleFor(item);
    final rawImage = asString(
      item[config.gridImageKey ?? 'image_url'],
      fallback: asString(item['image_path']),
    );
    final imageUrl = absoluteMediaUrl(rawImage.isEmpty ? null : rawImage);
    final price = config.gridPriceKey != null
        ? asDouble(item[config.gridPriceKey!])
        : null;
    final stock =
        config.gridStockKey != null ? asInt(item[config.gridStockKey!]) : null;
    final isActive = item.containsKey('is_active')
        ? asBool(item['is_active'], fallback: true)
        : true;
    final inStock = stock == null || stock > 0;

    return GestureDetector(
      onTap: onEdit,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.pkmnBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: PkNetworkImage(
                      imageUrl: imageUrl,
                      semanticLabel: title,
                      fit: BoxFit.contain,
                      padding: const EdgeInsets.all(8),
                      backgroundColor: AppColors.pkmnGrayLight,
                    ),
                  ),
                  if (!isActive || !inStock)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: inStock
                              ? AppColors.pkmnRed.withValues(alpha: 0.85)
                              : AppColors.pkmnGrayDark.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          inStock ? 'Inactive' : 'OOS',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body(size: 12),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (price != null)
                        Text(
                          '\$${price.toStringAsFixed(2)}',
                          style: AppTextStyles.heading(
                              size: 13, color: AppColors.pkmnBlue),
                        ),
                      const Spacer(),
                      if (stock != null)
                        Text(
                          'x$stock',
                          style: AppTextStyles.label(
                              color: inStock
                                  ? AppColors.pkmnGrayDark
                                  : AppColors.pkmnRed),
                        ),
                    ],
                  ),
                  if (onDelete != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                          onTap: onDelete,
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.delete_outline,
                                size: 16, color: AppColors.pkmnRed),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.pkmnGrayLight,
        border: Border.all(color: AppColors.pkmnBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: AppTextStyles.label(color: AppColors.pkmnGrayDark)
                  .copyWith(fontSize: 10)),
          const SizedBox(height: 2),
          Text(value.isEmpty ? '-' : value,
              style: AppTextStyles.body(size: 12)),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: active
            ? AppColors.pkmnBlueLight
            : AppColors.pkmnRed.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: AppTextStyles.label(
              color: active ? AppColors.pkmnBlueDark : AppColors.pkmnRed)),
    );
  }
}

class AdminResourceEditor extends ConsumerStatefulWidget {
  const AdminResourceEditor({required this.config, this.item, super.key});

  final AdminResourceConfig config;
  final Map<String, dynamic>? item;

  @override
  ConsumerState<AdminResourceEditor> createState() =>
      _AdminResourceEditorState();
}

class _AdminResourceEditorState extends ConsumerState<AdminResourceEditor> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _boolValues = {};
  bool _saving = false;

  // Image management (only for configs with supportsImageUpload)
  final _imagePicker = ImagePicker();
  List<Map<String, dynamic>> _existingImages = [];
  List<int> _originalImageOrder = [];
  List<int> _currentImageOrder = [];
  List<XFile> _pendingImages = [];

  bool get editing => widget.item != null;

  @override
  void initState() {
    super.initState();
    for (final field in widget.config.formFields) {
      final source = widget.item?[field.key] ?? field.defaultValue;
      if (field.type == AdminFieldType.boolean) {
        _boolValues[field.key] =
            asBool(source, fallback: asBool(field.defaultValue));
      } else {
        _controllers[field.key] =
            TextEditingController(text: _editorValue(source));
      }
    }
    if (widget.config.supportsImageUpload && widget.item != null) {
      _existingImages = asMapList(widget.item!['images']);
      _originalImageOrder =
          _existingImages.map((img) => asInt(img['id'])).toList();
      _currentImageOrder = List.from(_originalImageOrder);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.88),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Text(
                    editing
                        ? 'Edit ${widget.config.title}'
                        : 'New ${widget.config.title}',
                    style: AppTextStyles.heading(size: 22)),
                const SizedBox(height: 14),
                for (final field in widget.config.formFields) ...[
                  _buildField(field),
                  const SizedBox(height: 12),
                ],
                if (widget.config.supportsImageUpload) ...[
                  _buildImagesSection(),
                  const SizedBox(height: 12),
                ],
                PkButton(
                  label: editing ? 'Save Changes' : 'Create',
                  loading: _saving,
                  expand: true,
                  onPressed: _saving ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(AdminFormFieldConfig field) {
    if (field.type == AdminFieldType.boolean) {
      return SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(field.label),
        value: _boolValues[field.key] ?? false,
        onChanged: (value) => setState(() => _boolValues[field.key] = value),
      );
    }

    if (field.type == AdminFieldType.select) {
      final controller = _controllers[field.key]!;
      final current = field.options.contains(controller.text)
          ? controller.text
          : (field.options.isEmpty ? '' : field.options.first);
      controller.text = current;
      return DropdownButtonFormField<String>(
        initialValue: current,
        decoration: InputDecoration(
            labelText: field.label, helperText: field.helperText),
        items: [
          for (final option in field.options)
            DropdownMenuItem(value: option, child: Text(option))
        ],
        onChanged: (value) => controller.text = value ?? '',
      );
    }

    if (field.type == AdminFieldType.dateTime) {
      final controller = _controllers[field.key]!;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              readOnly: true,
              decoration: InputDecoration(
                labelText: field.label,
                helperText: field.helperText,
                suffixIcon: IconButton(
                  tooltip: 'Pick date',
                  icon: const Icon(Icons.calendar_today_outlined),
                  onPressed: () => _pickDate(controller),
                ),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              tooltip: 'Clear date',
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() => controller.clear()),
            ),
        ],
      );
    }

    final readOnly = editing && field.readOnlyWhenEditing;
    return TextFormField(
      controller: _controllers[field.key],
      readOnly: readOnly,
      minLines: field.type == AdminFieldType.multiline ? 3 : 1,
      maxLines: field.type == AdminFieldType.multiline ? 6 : 1,
      keyboardType: switch (field.type) {
        AdminFieldType.number => TextInputType.number,
        AdminFieldType.money =>
          const TextInputType.numberWithOptions(decimal: true),
        _ => TextInputType.text,
      },
      textCapitalization: field.uppercase
          ? TextCapitalization.characters
          : TextCapitalization.sentences,
      decoration:
          InputDecoration(labelText: field.label, helperText: field.helperText),
      validator: (value) {
        if (field.required && (value ?? '').trim().isEmpty) {
          return '${field.label} is required';
        }
        return null;
      },
    );
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    DateTime? initial;
    if (controller.text.isNotEmpty) {
      initial = DateTime.tryParse(controller.text);
    }
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date == null || !mounted) return;
    setState(() {
      controller.text = date.toIso8601String().substring(0, 10);
    });
  }

  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Images', style: AppTextStyles.heading(size: 16)),
        const SizedBox(height: 8),
        if (_existingImages.isNotEmpty && _pendingImages.isEmpty) ...[
          Text(
            'Drag to reorder (${_existingImages.length} image${_existingImages.length == 1 ? '' : 's'})',
            style: AppTextStyles.label(color: AppColors.pkmnGrayDark),
          ),
          const SizedBox(height: 6),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _existingImages.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final img = _existingImages.removeAt(oldIndex);
                _existingImages.insert(newIndex, img);
                final id = _currentImageOrder.removeAt(oldIndex);
                _currentImageOrder.insert(newIndex, id);
              });
            },
            itemBuilder: (context, index) {
              final img = _existingImages[index];
              final url = absoluteMediaUrl(
                  asString(img['url'], fallback: asString(img['image_url'])));
              return ListTile(
                key: ValueKey(img['id']),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
                leading: SizedBox(
                  width: 52,
                  height: 52,
                  child: PkNetworkImage(
                    imageUrl: url,
                    semanticLabel: 'Image ${index + 1}',
                    padding: const EdgeInsets.all(2),
                  ),
                ),
                title: Text('Image ${index + 1}',
                    style: AppTextStyles.body(size: 13)),
                trailing: ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
        if (_pendingImages.isNotEmpty) ...[
          Text(
            'New images (will replace existing)',
            style: AppTextStyles.label(color: AppColors.pkmnGrayDark),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _pendingImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.pkmnGrayLight,
                        border: Border.all(color: AppColors.pkmnBorder),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.image_outlined,
                          size: 28, color: AppColors.pkmnGrayDark),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _pendingImages.removeAt(index)),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: AppColors.pkmnRed,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Note: saving will upload these and replace any existing images.',
            style: AppTextStyles.label(color: AppColors.pkmnYellowDark)
                .copyWith(fontSize: 11),
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label:
              Text(_pendingImages.isEmpty ? 'Add Images' : 'Replace Selection'),
        ),
      ],
    );
  }

  Future<void> _pickImages() async {
    final picked = await _imagePicker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty || !mounted) return;
    setState(() => _pendingImages = picked);
  }

  bool _hasReordered() {
    if (_originalImageOrder.length != _currentImageOrder.length) return false;
    for (int i = 0; i < _originalImageOrder.length; i++) {
      if (_originalImageOrder[i] != _currentImageOrder[i]) return true;
    }
    return false;
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{};
      for (final field in widget.config.formFields) {
        if (editing && field.readOnlyWhenEditing) continue;
        if (field.type == AdminFieldType.boolean) {
          payload[field.key] = _boolValues[field.key] ?? false;
          continue;
        }
        final raw = (_controllers[field.key]?.text ?? '').trim();
        if (!field.required && raw.isEmpty) {
          payload[field.key] = null;
          continue;
        }
        payload[field.key] = switch (field.type) {
          AdminFieldType.number => int.tryParse(raw),
          AdminFieldType.money => raw,
          _ => field.uppercase ? raw.toUpperCase() : raw,
        };
      }

      final repo = ref.read(adminRepositoryProvider);
      final detailKey =
          editing ? widget.config.detailValue(widget.item!) : null;

      if (_pendingImages.isNotEmpty) {
        // Upload via multipart — sends fields + images in one request
        final stringFields = <String, dynamic>{};
        for (final entry in payload.entries) {
          if (entry.value != null) {
            stringFields[entry.key] = '${entry.value}';
          }
        }
        await repo.saveResourceMultipart(
          collectionPath: widget.config.writePath,
          fields: stringFields,
          imagePaths: _pendingImages.map((f) => f.path).toList(),
          detailKey: detailKey,
        );
      } else {
        await repo.saveResource(
          collectionPath: widget.config.writePath,
          detailKey: detailKey,
          payload: payload,
          usePut: widget.config.usePut,
        );
        // Reorder images if they were moved (only when no new upload)
        if (editing && _hasReordered() && _currentImageOrder.isNotEmpty) {
          final slug = asString(widget.item!['slug']);
          if (slug.isNotEmpty) {
            await repo.reorderItemImages(slug, _currentImageOrder);
          }
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$error')));
      setState(() => _saving = false);
    }
  }

  String _editorValue(Object? value) {
    if (value == null) return '';
    if (value is bool) return value ? 'true' : 'false';
    return '$value';
  }
}

String _formatValue(Object? value, {bool money = false}) {
  if (value == null) return '';
  if (value is bool) return value ? 'Yes' : 'No';
  if (money) return '\$${asDouble(value).toStringAsFixed(2)}';
  return '$value';
}
