import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class PkBadge extends StatelessWidget {
  const PkBadge({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.pkmnRed,
        border: Border.all(color: AppColors.pkmnRedDark),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          count > 99 ? '99+' : '$count',
          style:
              AppTextStyles.label(color: Colors.white).copyWith(fontSize: 10),
        ),
      ),
    );
  }
}
