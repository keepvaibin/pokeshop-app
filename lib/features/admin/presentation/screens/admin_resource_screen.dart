import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/json_helpers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/pk_button.dart';
import '../../../../core/widgets/pk_card.dart';
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
    titleKeys: ['title', 'name'],
    searchFields: ['title', 'description', 'tcg_set_name', 'rarity'],
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
      await ref.read(adminRepositoryProvider).saveResource(
            collectionPath: widget.config.writePath,
            detailKey: editing ? widget.config.detailValue(widget.item!) : null,
            payload: payload,
            usePut: widget.config.usePut,
          );
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
