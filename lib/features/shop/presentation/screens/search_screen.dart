import 'package:flutter/material.dart';

import 'shop_screen.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const ShopScreen(showInlineSearch: true, title: 'Search');
}
