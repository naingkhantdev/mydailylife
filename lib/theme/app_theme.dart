import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'app_radii.dart';
import 'app_text_styles.dart';

/// Builds a complete [ThemeData] from an [AppPalette].
///
/// Light and dark are the *same* function applied to two palettes rather than
/// two hand-maintained theme blocks, so a component styled once can never end
/// up configured in one appearance and forgotten in the other. The palette is
/// also attached as a `ThemeExtension`, which is what makes `context.palette`
/// resolve correctly inside every widget below `MaterialApp`.
class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(AppPalette.light);

  static ThemeData dark() => _build(AppPalette.dark);

  static ThemeData _build(AppPalette palette) {
    final isDark = palette.isDark;

    return ThemeData(
      useMaterial3: true,
      brightness: palette.brightness,
      extensions: <ThemeExtension<dynamic>>[palette],
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppPalette.light.primary,
        brightness: palette.brightness,
      ).copyWith(
        // Pin the brand colours instead of letting the seed approximate them.
        // onPrimary is navy in dark mode because the action colour there is the
        // bright cyan, which cannot carry white text.
        primary: palette.primary,
        onPrimary: palette.onPrimary,
        secondary: palette.secondary,
        onSecondary: palette.onSecondary,
        tertiary: palette.tertiary,
        surface: palette.surface,
        onSurface: palette.ink,
        error: palette.danger,
        onError: isDark ? AppPalette.light.primary : Colors.white,
        outline: palette.border,
      ),
      scaffoldBackgroundColor: palette.background,
      canvasColor: palette.surface,
      dividerColor: palette.divider,
      shadowColor: palette.shadow,
      fontFamily: AppTextStyles.fontFamily,
      fontFamilyFallback: AppTextStyles.fontFamilyFallback,
      textTheme: AppTextStyles.textThemeFor(palette),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.ink,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTextStyles.appBarTitleFor(palette),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
      ),
      iconTheme: IconThemeData(color: palette.bodyText),
      listTileTheme: ListTileThemeData(
        iconColor: palette.bodyText,
        titleTextStyle: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontFamilyFallback: AppTextStyles.fontFamilyFallback,
          color: palette.ink,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1.25,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: palette.onPrimary,
          textStyle: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontFamilyFallback: AppTextStyles.fontFamilyFallback,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.ink,
          textStyle: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontFamilyFallback: AppTextStyles.fontFamilyFallback,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
          side: BorderSide(color: palette.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? palette.primary : palette.ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: BorderSide(color: palette.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        // In light mode the field sits a shade *below* the white card it lives
        // on; in dark mode that inverts, so the field lifts above the surface.
        fillColor: isDark ? palette.heroSurface : palette.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: palette.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: palette.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: palette.danger, width: 1.5),
        ),
        labelStyle: TextStyle(color: palette.mutedText),
        hintStyle: TextStyle(color: palette.mutedText),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.xl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.heroSurface,
        contentTextStyle: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontFamilyFallback: AppTextStyles.fontFamilyFallback,
          color: palette.onInk,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.background,
        selectedColor: palette.primary,
        checkmarkColor: palette.onPrimary,
        side: BorderSide(color: palette.border),
        labelStyle: TextStyle(
          color: palette.bodyText,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
