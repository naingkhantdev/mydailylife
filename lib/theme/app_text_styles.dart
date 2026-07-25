import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  static final fontFamily = GoogleFonts.inter().fontFamily;

  static final textTheme = TextTheme(
    headlineMedium: GoogleFonts.inter(
      color: AppColors.ink,
      fontSize: 26,
      fontWeight: FontWeight.w700,
      height: 1.18,
      letterSpacing: -0.5,
    ),
    titleLarge: GoogleFonts.inter(
      color: AppColors.ink,
      fontSize: 19,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: -0.2,
    ),
    titleMedium: GoogleFonts.inter(
      color: AppColors.ink,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: 0,
    ),
    bodyLarge: GoogleFonts.inter(
      color: AppColors.ink,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.45,
      letterSpacing: 0,
    ),
    bodyMedium: GoogleFonts.inter(
      color: AppColors.ink,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.4,
      letterSpacing: 0,
    ),
    bodySmall: GoogleFonts.inter(
      color: AppColors.mutedText,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.35,
      letterSpacing: 0,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: 0,
    ),
  );

  static final appBarTitle = GoogleFonts.inter(
    color: AppColors.ink,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.2,
  );
}
