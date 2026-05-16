import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/cart_icon_button.dart';
import '../../data/shop_repository.dart';
import '../widgets/product_card.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen(
      {this.showInlineSearch = false,
      this.title = 'Shop',
      this.initialCategory,
      this.initialSort = 'featured',
      super.key});

  final bool showInlineSearch;
  final String title;
  final String? initialCategory;
  final String initialSort;

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  late String? _category;
  late String _sort;
  bool _inStockOnly = false;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _sort = widget.initialSort;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ShopQuery(
      search: _query,
      category: _category,
      sort: _sort,
      inStockOnly: _inStockOnly,
    );
    final items = ref.watch(shopItemsProvider(query));
    final categories = ref.watch(shopCategoriesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (!widget.showInlineSearch)
            IconButton(
                onPressed: () {
                  final location = GoRouterState.of(context).matchedLocation;
                  final prefix = location.startsWith('/admin') ? '/admin' : '';
                  context.push('$prefix/search');
                },
                icon: const Icon(Icons.search)),
          const CartIconButton(),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.showInlineSearch) ...[
                  SearchBar(
                    controller: _searchController,
                    hintText: 'Search cards, sealed, accessories',
                    leading: const Icon(Icons.search),
                    trailing: [
                      IconButton(
                          onPressed: () =>
                              setState(() => _query = _searchController.text),
                          icon: const Icon(Icons.arrow_forward))
                    ],
                    onChanged: (value) {
                      if (value.isEmpty && _query.isNotEmpty) {
                        setState(() => _query = '');
                      }
                    },
                    onSubmitted: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 12),
                ],
                categories.when(
                  loading: () => const SizedBox(height: 36),
                  error: (error, stackTrace) => const SizedBox.shrink(),
                  data: (values) => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: const Text('All'),
                            selected: _category == null,
                            onSelected: (_) => setState(() => _category = null),
                          ),
                        ),
                        for (final category in values)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(category.name),
                              selected: _category == category.slug,
                              onSelected: (_) =>
                                  setState(() => _category = category.slug),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _sort,
                        decoration: const InputDecoration(labelText: 'Sort'),
                        items: const [
                          DropdownMenuItem(
                              value: 'featured', child: Text('Featured')),
                          DropdownMenuItem(
                              value: 'newest', child: Text('Newest')),
                          DropdownMenuItem(
                              value: 'price-low', child: Text('Price low')),
                          DropdownMenuItem(
                              value: 'price-high', child: Text('Price high')),
                          DropdownMenuItem(value: 'name', child: Text('Name')),
                          DropdownMenuItem(
                              value: 'stock-low', child: Text('Stock low')),
                        ],
                        onChanged: (value) =>
                            setState(() => _sort = value ?? 'featured'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilterChip(
                      label: const Text('In stock'),
                      selected: _inStockOnly,
                      onSelected: (value) =>
                          setState(() => _inStockOnly = value),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: items.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(child: Text('$error')),
              data: (products) {
                if (products.isEmpty) {
                  return Center(
                      child: Text('No products found.',
                          style: AppTextStyles.body()));
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 1000
                        ? 4
                        : constraints.maxWidth >= 680
                            ? 3
                            : 2;
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.62,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) =>
                          ProductCard(item: products[index]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
