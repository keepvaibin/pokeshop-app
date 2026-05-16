import 'package:flutter/material.dart';

import '../theme/app_decorations.dart';

class PkCard extends StatelessWidget {
  const PkCard(
      {required this.child,
      this.padding = const EdgeInsets.all(16),
      super.key});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppDecorations.panel(),
      child: Padding(padding: padding, child: child),
    );
  }
}
