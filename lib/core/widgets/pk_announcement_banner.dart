import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class PkAnnouncementBanner extends StatelessWidget {
  const PkAnnouncementBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    if (message.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: AppColors.pkmnYellow,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: SafeArea(
        bottom: false,
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.label(color: AppColors.pkmnText),
        ),
      ),
    );
  }
}
