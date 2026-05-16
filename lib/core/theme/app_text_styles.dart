import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static TextStyle heading({
    double size = 22,
    FontWeight weight = FontWeight.w800,
    Color color = AppColors.pkmnText,
  }) {
    return GoogleFonts.montserrat(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: 0,
      height: 1.15,
    );
  }

  static TextStyle body({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.pkmnGray,
  }) {
    return GoogleFonts.openSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: 0,
      height: 1.4,
    );
  }

  static TextStyle label({Color color = AppColors.pkmnText}) {
    return GoogleFonts.montserrat(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: 0.8,
      height: 1.2,
    );
  }
}
