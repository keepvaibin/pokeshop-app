import 'package:flutter/material.dart';

import '../theme/app_decorations.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum PkButtonVariant { primary, secondary, accent, destructive }

class PkButton extends StatelessWidget {
  const PkButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = PkButtonVariant.primary,
    this.expand = false,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final PkButtonVariant variant;
  final bool expand;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colors = _colors();
    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: colors.foreground),
          )
        else if (icon != null)
          IconTheme(
              data: IconThemeData(color: colors.foreground, size: 18),
              child: icon!),
        if (loading || icon != null) const SizedBox(width: 8),
        Flexible(
          child: Text(
            label.toUpperCase(),
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.label(color: colors.foreground),
          ),
        ),
      ],
    );

    return SizedBox(
      width: expand ? double.infinity : null,
      child: Material(
        color: onPressed == null ? AppColors.pkmnDisabled : colors.background,
        shape: RoundedRectangleBorder(
          borderRadius: AppDecorations.controlRadius,
          side: BorderSide(
              color:
                  onPressed == null ? AppColors.pkmnDisabled : colors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: AppDecorations.controlRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            child: child,
          ),
        ),
      ),
    );
  }

  ({Color background, Color foreground, Color border}) _colors() {
    return switch (variant) {
      PkButtonVariant.primary => (
          background: AppColors.pkmnBlue,
          foreground: Colors.white,
          border: AppColors.pkmnBlue,
        ),
      PkButtonVariant.secondary => (
          background: Colors.white,
          foreground: AppColors.pkmnText,
          border: AppColors.pkmnGrayMid,
        ),
      PkButtonVariant.accent => (
          background: AppColors.pkmnYellow,
          foreground: AppColors.pkmnText,
          border: AppColors.pkmnYellow,
        ),
      PkButtonVariant.destructive => (
          background: AppColors.pkmnRed,
          foreground: Colors.white,
          border: AppColors.pkmnRed,
        ),
    };
  }
}
