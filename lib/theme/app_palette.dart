import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Theme-aware colour set for the app.
///
/// `AppColors` holds raw, compile-time constants and is therefore locked to a
/// single appearance. `AppPalette` is the light/dark-aware layer on top: it is
/// registered as a [ThemeExtension] on both `ThemeData`s and read through
/// `context.palette`, so every colour resolves against whichever theme is
/// active.
///
/// Migration note: screens still reading `AppColors.*` directly keep rendering
/// light colours in both themes. They are being moved over to
/// `context.palette.*` file by file.
///
/// Two tokens exist here that `AppColors` has no equivalent for, because the
/// old palette overloaded a single constant for two jobs:
///  * [heroSurface] — the dark "ink" hero-card background. Previously this was
///    `AppColors.ink`, the same constant used for primary text. Text has to
///    invert in dark mode; the hero card must stay dark, so they split.
///  * [shadow] — box shadows were hardcoded slate alphas that vanish on a dark
///    background and need a much heavier value there.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.tertiary,
    required this.background,
    required this.surface,
    required this.border,
    required this.divider,
    required this.ink,
    required this.bodyText,
    required this.mutedText,
    required this.heroSurface,
    required this.shadow,
    required this.blue,
    required this.blueSoft,
    required this.violet,
    required this.violetSoft,
    required this.coral,
    required this.coralSoft,
    required this.gold,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.softMint,
    required this.navy,
    required this.navyMid,
    required this.onInk,
    required this.onInkMuted,
    required this.onInkFaint,
    required this.onInkBorder,
    required this.onInkSurface,
    required this.onInkAccent,
  });

  final Brightness brightness;

  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color tertiary;

  final Color background;
  final Color surface;
  final Color border;
  final Color divider;

  final Color ink;
  final Color bodyText;
  final Color mutedText;

  final Color heroSurface;
  final Color shadow;

  final Color blue;
  final Color blueSoft;
  final Color violet;
  final Color violetSoft;
  final Color coral;
  final Color coralSoft;
  final Color gold;

  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color softMint;

  final Color navy;
  final Color navyMid;

  // Content sitting on [heroSurface]. That surface is dark in *both* themes,
  // so these do not change between light and dark.
  final Color onInk;
  final Color onInkMuted;
  final Color onInkFaint;
  final Color onInkBorder;
  final Color onInkSurface;
  final Color onInkAccent;

  bool get isDark => brightness == Brightness.dark;

  static const light = AppPalette(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    secondary: AppColors.secondary,
    onSecondary: AppColors.primary,
    tertiary: AppColors.tertiary,
    background: AppColors.background,
    surface: AppColors.surface,
    border: AppColors.border,
    divider: AppColors.divider,
    ink: AppColors.ink,
    bodyText: AppColors.bodyText,
    mutedText: AppColors.mutedText,
    heroSurface: AppColors.ink,
    shadow: Color(0x1A0F172A),
    blue: AppColors.blue,
    blueSoft: AppColors.blueSoft,
    violet: AppColors.violet,
    violetSoft: AppColors.violetSoft,
    coral: AppColors.coral,
    coralSoft: AppColors.coralSoft,
    gold: AppColors.gold,
    success: AppColors.success,
    successSoft: AppColors.successSoft,
    warning: AppColors.warning,
    warningSoft: AppColors.warningSoft,
    danger: AppColors.danger,
    softMint: AppColors.softMint,
    navy: AppColors.navy,
    navyMid: AppColors.navyMid,
    onInk: AppColors.onInk,
    onInkMuted: AppColors.onInkMuted,
    onInkFaint: AppColors.onInkFaint,
    onInkBorder: AppColors.onInkBorder,
    onInkSurface: AppColors.onInkSurface,
    onInkAccent: AppColors.onInkAccent,
  );

  /// Dark appearance.
  ///
  /// The navy primary cannot carry buttons or navigation on a dark background —
  /// #001935 on #0B1220 is effectively invisible. So in dark mode the brand
  /// inverts: the cyan becomes the action colour and navy becomes the text on
  /// top of it (11.7:1). Accents are all lifted to their 300/400 tones so they
  /// stay legible on dark surfaces, and the pale tint backgrounds become deep,
  /// low-saturation versions of the same hue.
  static const dark = AppPalette(
    brightness: Brightness.dark,
    primary: Color(0xFF2FE8FF),
    onPrimary: AppColors.primary,
    secondary: Color(0xFFA5F3FC),
    onSecondary: AppColors.primary,
    tertiary: Color(0xFF67E8F9),
    background: Color(0xFF0B1220),
    surface: Color(0xFF111C2E),
    border: Color(0xFF1E2D45),
    divider: Color(0xFF26374F),
    ink: Color(0xFFF1F5F9),
    bodyText: Color(0xFFCBD5E1),
    mutedText: Color(0xFF94A3B8),
    // Slightly lighter than [surface] so hero cards still read as elevated
    // rather than disappearing into the page.
    heroSurface: Color(0xFF16233A),
    shadow: Color(0x66000000),
    blue: Color(0xFF67E8F9),
    blueSoft: Color(0xFF10303A),
    violet: Color(0xFF60A5FA),
    violetSoft: Color(0xFF14263D),
    coral: Color(0xFFFB8A6B),
    coralSoft: Color(0xFF33201B),
    gold: Color(0xFFFCD34D),
    success: Color(0xFF4ADE80),
    successSoft: Color(0xFF102A1B),
    warning: Color(0xFFFBBF24),
    warningSoft: Color(0xFF2E2311),
    danger: Color(0xFFF87171),
    softMint: Color(0xFF10281E),
    navy: AppColors.navy,
    navyMid: AppColors.navyMid,
    onInk: AppColors.onInk,
    onInkMuted: AppColors.onInkMuted,
    onInkFaint: AppColors.onInkFaint,
    onInkBorder: AppColors.onInkBorder,
    onInkSurface: AppColors.onInkSurface,
    onInkAccent: AppColors.onInkAccent,
  );

  @override
  AppPalette copyWith({
    Brightness? brightness,
    Color? primary,
    Color? onPrimary,
    Color? secondary,
    Color? onSecondary,
    Color? tertiary,
    Color? background,
    Color? surface,
    Color? border,
    Color? divider,
    Color? ink,
    Color? bodyText,
    Color? mutedText,
    Color? heroSurface,
    Color? shadow,
    Color? blue,
    Color? blueSoft,
    Color? violet,
    Color? violetSoft,
    Color? coral,
    Color? coralSoft,
    Color? gold,
    Color? success,
    Color? successSoft,
    Color? warning,
    Color? warningSoft,
    Color? danger,
    Color? softMint,
    Color? navy,
    Color? navyMid,
    Color? onInk,
    Color? onInkMuted,
    Color? onInkFaint,
    Color? onInkBorder,
    Color? onInkSurface,
    Color? onInkAccent,
  }) {
    return AppPalette(
      brightness: brightness ?? this.brightness,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      tertiary: tertiary ?? this.tertiary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      ink: ink ?? this.ink,
      bodyText: bodyText ?? this.bodyText,
      mutedText: mutedText ?? this.mutedText,
      heroSurface: heroSurface ?? this.heroSurface,
      shadow: shadow ?? this.shadow,
      blue: blue ?? this.blue,
      blueSoft: blueSoft ?? this.blueSoft,
      violet: violet ?? this.violet,
      violetSoft: violetSoft ?? this.violetSoft,
      coral: coral ?? this.coral,
      coralSoft: coralSoft ?? this.coralSoft,
      gold: gold ?? this.gold,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      warning: warning ?? this.warning,
      warningSoft: warningSoft ?? this.warningSoft,
      danger: danger ?? this.danger,
      softMint: softMint ?? this.softMint,
      navy: navy ?? this.navy,
      navyMid: navyMid ?? this.navyMid,
      onInk: onInk ?? this.onInk,
      onInkMuted: onInkMuted ?? this.onInkMuted,
      onInkFaint: onInkFaint ?? this.onInkFaint,
      onInkBorder: onInkBorder ?? this.onInkBorder,
      onInkSurface: onInkSurface ?? this.onInkSurface,
      onInkAccent: onInkAccent ?? this.onInkAccent,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      primary: mix(primary, other.primary),
      onPrimary: mix(onPrimary, other.onPrimary),
      secondary: mix(secondary, other.secondary),
      onSecondary: mix(onSecondary, other.onSecondary),
      tertiary: mix(tertiary, other.tertiary),
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      border: mix(border, other.border),
      divider: mix(divider, other.divider),
      ink: mix(ink, other.ink),
      bodyText: mix(bodyText, other.bodyText),
      mutedText: mix(mutedText, other.mutedText),
      heroSurface: mix(heroSurface, other.heroSurface),
      shadow: mix(shadow, other.shadow),
      blue: mix(blue, other.blue),
      blueSoft: mix(blueSoft, other.blueSoft),
      violet: mix(violet, other.violet),
      violetSoft: mix(violetSoft, other.violetSoft),
      coral: mix(coral, other.coral),
      coralSoft: mix(coralSoft, other.coralSoft),
      gold: mix(gold, other.gold),
      success: mix(success, other.success),
      successSoft: mix(successSoft, other.successSoft),
      warning: mix(warning, other.warning),
      warningSoft: mix(warningSoft, other.warningSoft),
      danger: mix(danger, other.danger),
      softMint: mix(softMint, other.softMint),
      navy: mix(navy, other.navy),
      navyMid: mix(navyMid, other.navyMid),
      onInk: mix(onInk, other.onInk),
      onInkMuted: mix(onInkMuted, other.onInkMuted),
      onInkFaint: mix(onInkFaint, other.onInkFaint),
      onInkBorder: mix(onInkBorder, other.onInkBorder),
      onInkSurface: mix(onInkSurface, other.onInkSurface),
      onInkAccent: mix(onInkAccent, other.onInkAccent),
    );
  }
}

/// Shorthand so widgets read `context.palette.ink` instead of the much longer
/// `Theme.of(context).extension<AppPalette>()!`.
extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
