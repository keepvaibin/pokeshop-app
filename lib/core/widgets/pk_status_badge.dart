import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class PkStatusBadge extends StatelessWidget {
  const PkStatusBadge({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final config = _config(status);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: config.background,
        border: Border.all(color: config.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(config.label.toUpperCase(),
            style: AppTextStyles.label(color: config.foreground)),
      ),
    );
  }

  ({String label, Color background, Color foreground, Color border}) _config(
      String value) {
    return switch (value) {
      'fulfilled' || 'completed' => (
          label: 'Completed',
          background: const Color(0xFFE6F5EA),
          foreground: const Color(0xFF1A7F37),
          border: const Color(0xFFB9E2C5),
        ),
      'cancelled' || 'rejected' => (
          label: 'Cancelled',
          background: const Color(0xFFFBE8E9),
          foreground: AppColors.pkmnRed,
          border: const Color(0xFFF3BEC1),
        ),
      'pending_counteroffer' => (
          label: 'Counteroffer',
          background: const Color(0xFFFFF3CC),
          foreground: AppColors.pkmnYellowDark,
          border: const Color(0xFFFFD978),
        ),
      'trade_review' || 'pending_review' => (
          label: 'Review',
          background: AppColors.pkmnBlueLight,
          foreground: AppColors.pkmnBlueDark,
          border: AppColors.pkmnBlue,
        ),
      _ => (
          label: value.replaceAll('_', ' '),
          background: Colors.white,
          foreground: AppColors.pkmnGray,
          border: AppColors.pkmnGrayMid,
        ),
    };
  }
}
