import 'package:flutter/material.dart';

import 'shop_screen.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen(
      {this.initialSearch = '', this.initialFilters = const {}, super.key});

  final String initialSearch;
  final Map<String, String> initialFilters;

  @override
  Widget build(BuildContext context) => ShopScreen(
        showInlineSearch: true,
        title: 'Search',
        initialSearch: initialSearch,
        initialFilters: initialFilters,
      );
}
