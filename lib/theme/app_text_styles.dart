import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_palette.dart';

class AppTextStyles {
  const AppTextStyles._();

  static final fontFamily = GoogleFonts.inter().fontFamily;

  /// Myanmar (Burmese) script support.
  ///
  /// Inter carries no Myanmar glyphs, so Burmese text renders as tofu boxes
  /// (□□□) without this. Flutter resolves `fontFamilyFallback` per glyph, not
  /// per string, so Latin characters keep using Inter and only Myanmar
  /// codepoints fall through to Noto Sans Myanmar — mixed-script lines like
  /// "Gym အချိန်" render correctly from a single style.
  static final myanmarFontFamily = GoogleFonts.notoSansMyanmar().fontFamily!;

  static final fontFamilyFallback = <String>[myanmarFontFamily];

  /// Every style in the app funnels through here so no text can accidentally
  /// ship without the Myanmar fallback attached.
  static TextStyle _scriptAware(TextStyle style) =>
      style.copyWith(fontFamilyFallback: fontFamilyFallback);

  /// Built per theme rather than held as a constant, because the text colours
  /// have to invert between light and dark.
  static TextTheme textThemeFor(AppPalette palette) => TextTheme(
        headlineMedium: _scriptAware(
          GoogleFonts.inter(
            color: palette.ink,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            height: 1.18,
            letterSpacing: -0.5,
          ),
        ),
        titleLarge: _scriptAware(
          GoogleFonts.inter(
            color: palette.ink,
            fontSize: 19,
            fontWeight: FontWeight.w700,
            height: 1.2,
            letterSpacing: -0.2,
          ),
        ),
        titleMedium: _scriptAware(
          GoogleFonts.inter(
            color: palette.ink,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.25,
            letterSpacing: 0,
          ),
        ),
        bodyLarge: _scriptAware(
          GoogleFonts.inter(
            color: palette.ink,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.45,
            letterSpacing: 0,
          ),
        ),
        bodyMedium: _scriptAware(
          GoogleFonts.inter(
            color: palette.ink,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.4,
            letterSpacing: 0,
          ),
        ),
        bodySmall: _scriptAware(
          GoogleFonts.inter(
            color: palette.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.35,
            letterSpacing: 0,
          ),
        ),
        labelLarge: _scriptAware(
          GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.2,
            letterSpacing: 0,
          ),
        ),
      );

  static TextStyle appBarTitleFor(AppPalette palette) => _scriptAware(
        GoogleFonts.inter(
          color: palette.ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 1.2,
          letterSpacing: -0.2,
        ),
      );
}
