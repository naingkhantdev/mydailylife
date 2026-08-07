import 'package:flutter/material.dart';

/// The app's single source of colour truth.
///
/// The palette is navy + cyan: a near-black navy carries navigation,
/// buttons and the AppBar, while the bright cyan is reserved for
/// highlights and active states. Cyan is deliberately never used as a
/// foreground on light surfaces — at #2FE8FF it is far too pale to read
/// against white, so it only ever appears on the dark "ink" surfaces or
/// as a fill.
///
/// Token names predate this palette and are kept as-is so the 270 call
/// sites across the app keep working. Their roles now read as:
///   primary / navy    -> navy chrome
///   secondary         -> cyan highlight (dark surfaces only)
///   blue / blueSoft   -> the neutral informational accent pair
///   violet/violetSoft -> the deep ocean-blue accent pair (gradients, empty states)
///   coral/coralSoft   -> the warm meal + "missed" accent pair
class AppColors {
  const AppColors._();

  static const primary = Color(0xFF001935);
  static const secondary = Color(0xFF2FE8FF);
  static const tertiary = Color(0xFF0E7490);
  static const navy = Color(0xFF0A2A4A);
  static const navyMid = Color(0xFF041F3A);
  static const violet = Color(0xFF0F4C81);
  static const blue = Color(0xFF0E7490);
  static const coral = Color(0xFFEF6144);
  static const gold = Color(0xFFFBBF24);
  static const ink = Color(0xFF0F172A);

  static const background = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE2E8F0);
  static const divider = Color(0xFFCBD5E1);
  static const mutedText = Color(0xFF64748B);
  static const bodyText = Color(0xFF475569);

  // Status colours. These are the contrast-safe renderings of the design
  // system's #22C55E / #F59E0B / #EF4444: all three are used as text and
  // icon colours (routine chips, the drawer sync row, delete buttons), and
  // the brighter originals fall below 4.5:1 on white. The bright values
  // survive as the *Soft tints and as fills via withOpacity.
  static const success = Color(0xFF15803D);
  static const warning = Color(0xFFB45309);
  static const danger = Color(0xFFDC2626);

  static const softMint = Color(0xFFECFDF5);
  static const successSoft = Color(0xFFF0FDF4);
  static const warningSoft = Color(0xFFFFFBEB);
  static const violetSoft = Color(0xFFEAF2FB);
  static const blueSoft = Color(0xFFECFEFF);
  static const coralSoft = Color(0xFFFEF0EC);

  // Text/border colors for content sitting on a dark "ink" surface
  // (hero cards, splash screen). Keeps the on-dark palette consistent
  // instead of each hero card hardcoding its own near-white grays.
  static const onInk = Colors.white;
  static const onInkMuted = Color(0xFFCBD5E1);
  static const onInkFaint = Color(0xFF94A3B8);
  static const onInkBorder = Color(0x26FFFFFF);
  static const onInkSurface = Color(0x1FFFFFFF);
  static const onInkAccent = secondary;
}
