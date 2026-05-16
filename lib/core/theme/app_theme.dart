import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_decorations.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static const RoundedRectangleBorder rounded = RoundedRectangleBorder(
    borderRadius: AppDecorations.controlRadius,
  );

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.pkmnBlue,
        primary: AppColors.pkmnBlue,
        secondary: AppColors.pkmnYellow,
        error: AppColors.pkmnRed,
        surface: Colors.white,
        surfaceContainerLowest: AppColors.pkmnBg,
      ),
      scaffoldBackgroundColor: AppColors.pkmnBg,
    );
    return _applyShared(base, brightness: Brightness.light);
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.pkmnBlueLight,
        brightness: Brightness.dark,
        primary: AppColors.pkmnBlueLight,
        secondary: AppColors.pkmnYellow,
        error: AppColors.pkmnRed,
        surface: AppColors.darkSurface,
        surfaceContainerLowest: AppColors.darkBg,
      ),
      scaffoldBackgroundColor: AppColors.darkBg,
    );
    return _applyShared(base, brightness: Brightness.dark);
  }

  static ThemeData _applyShared(ThemeData base,
      {required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.pkmnText;
    final bodyColor = isDark ? AppColors.darkMuted : AppColors.pkmnGray;

    return base.copyWith(
      textTheme: GoogleFonts.openSansTextTheme(base.textTheme).copyWith(
        headlineLarge: AppTextStyles.heading(size: 34, color: textColor),
        headlineMedium: AppTextStyles.heading(size: 28, color: textColor),
        titleLarge: AppTextStyles.heading(size: 22, color: textColor),
        titleMedium: AppTextStyles.heading(size: 18, color: textColor),
        bodyLarge: AppTextStyles.body(size: 16, color: bodyColor),
        bodyMedium: AppTextStyles.body(color: bodyColor),
        labelLarge: AppTextStyles.label(color: textColor),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        foregroundColor: textColor,
        titleTextStyle: AppTextStyles.heading(size: 18, color: textColor),
        shape: const Border(
          bottom: BorderSide(color: AppColors.pkmnBorder),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isDark ? AppColors.darkPanel : Colors.white,
        shape: rounded.copyWith(
          side: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.pkmnBorder),
        ),
      ),
      elevatedButtonTheme:
          ElevatedButtonThemeData(style: _buttonStyle(filled: true)),
      filledButtonTheme:
          FilledButtonThemeData(style: _buttonStyle(filled: true)),
      outlinedButtonTheme:
          OutlinedButtonThemeData(style: _buttonStyle(filled: false)),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.pkmnBlue,
          textStyle: AppTextStyles.label(color: AppColors.pkmnBlue),
          shape: rounded,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : Colors.white,
        border: const OutlineInputBorder(
            borderRadius: AppDecorations.controlRadius),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDecorations.controlRadius,
          borderSide: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.pkmnGrayMid),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppDecorations.controlRadius,
          borderSide: BorderSide(color: AppColors.pkmnBlue, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: rounded,
      ),
      dialogTheme: const DialogThemeData(shape: rounded),
      chipTheme: base.chipTheme.copyWith(
        shape: rounded,
        side: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.pkmnGrayMid),
        labelStyle: AppTextStyles.label(color: textColor),
      ),
      snackBarTheme: SnackBarThemeData(
        shape: rounded,
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.darkPanel : AppColors.pkmnText,
        contentTextStyle: AppTextStyles.body(color: Colors.white),
      ),
      dividerTheme: DividerThemeData(
          color: isDark ? AppColors.darkBorder : AppColors.pkmnBorder),
      extensions: const <ThemeExtension<dynamic>>[],
    );
  }

  static ButtonStyle _buttonStyle({required bool filled}) {
    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
      shape: const WidgetStatePropertyAll(rounded),
      textStyle:
          WidgetStatePropertyAll(AppTextStyles.label(color: Colors.white)),
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStatePropertyAll(
          filled ? AppColors.pkmnBlue : Colors.transparent),
      foregroundColor:
          WidgetStatePropertyAll(filled ? Colors.white : AppColors.pkmnBlue),
      side: const WidgetStatePropertyAll(BorderSide(color: AppColors.pkmnBlue)),
    );
  }

  static InputDecoration input(String label, {String? hint}) {
    return AppDecorations.inputDecoration(label: label, hint: hint);
  }
}
