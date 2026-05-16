import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';

class PkShimmer extends StatelessWidget {
  const PkShimmer({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.pkmnBorder,
      highlightColor: AppColors.pkmnGrayLight,
      child: child,
    );
  }
}
