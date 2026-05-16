import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppDecorations {
  static const BorderRadius panelRadius = BorderRadius.all(Radius.circular(18));
  static const BorderRadius controlRadius =
      BorderRadius.all(Radius.circular(12));

  static const BoxShadow cardShadow = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 2,
    offset: Offset(0, 1),
  );

  static const BoxShadow hoverShadow = BoxShadow(
    color: Color(0x1F000000),
    blurRadius: 10,
    offset: Offset(0, 4),
  );

  static BoxDecoration panel({Color color = Colors.white}) {
    return BoxDecoration(
      color: color,
      border: Border.all(color: AppColors.pkmnBorder),
      borderRadius: panelRadius,
      boxShadow: const [cardShadow],
    );
  }

  static BoxDecoration filterPanel() {
    return BoxDecoration(
      color: const Color(0xFFF5F5F5),
      border: Border.all(color: AppColors.pkmnBorder),
      borderRadius: panelRadius,
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
      ],
    );
  }

  static InputDecoration inputDecoration({String? label, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: const OutlineInputBorder(borderRadius: controlRadius),
      enabledBorder: const OutlineInputBorder(
        borderRadius: controlRadius,
        borderSide: BorderSide(color: AppColors.pkmnGrayMid),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: controlRadius,
        borderSide: BorderSide(color: AppColors.pkmnBlue, width: 2),
      ),
    );
  }
}
