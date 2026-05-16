import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class PkPill extends StatelessWidget {
  const PkPill(
      {required this.label, this.color = AppColors.pkmnText, super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.pkmnGrayMid),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child:
            Text(label.toUpperCase(), style: AppTextStyles.label(color: color)),
      ),
    );
  }
}
