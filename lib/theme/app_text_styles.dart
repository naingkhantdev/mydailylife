import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  static const fontFamily = 'Roboto';

  static const textTheme = TextTheme(
    headlineMedium: TextStyle(
      fontFamily: fontFamily,
      color: AppColors.ink,
      fontSize: 26,
      fontWeight: FontWeight.w700,
      height: 1.18,
      letterSpacing: -0.5,
    ),
    titleLarge: TextStyle(
      fontFamily: fontFamily,
      color: AppColors.ink,
      fontSize: 19,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: -0.2,
    ),
    titleMedium: TextStyle(
      fontFamily: fontFamily,
      color: AppColors.ink,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: 0,
    ),
    bodyLarge: TextStyle(
      fontFamily: fontFamily,
      color: AppColors.ink,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.45,
      letterSpacing: 0,
    ),
    bodyMedium: TextStyle(
      fontFamily: fontFamily,
      color: AppColors.ink,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.4,
      letterSpacing: 0,
    ),
    bodySmall: TextStyle(
      fontFamily: fontFamily,
      color: AppColors.mutedText,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.35,
      letterSpacing: 0,
    ),
    labelLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: 0,
    ),
  );

  static const appBarTitle = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.ink,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.2,
  );
}
