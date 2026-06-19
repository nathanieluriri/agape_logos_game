import 'package:flutter/material.dart';

/// Raw color palette - the single source of truth for color.
///
/// Widgets must NOT use literal `Color(...)` values; reference these tokens
/// (or, preferably, the `ColorScheme` produced by `AppTheme`) instead.
abstract final class AppColors {
  const AppColors._();

  static const Color seed = Color(0xFF5B8A72);
  static const Color ink = Color(0xFF1A1C1A);
  static const Color paper = Color(0xFFF7F4EC);
  static const Color paperDark = Color(0xFF14160F);
  static const Color accent = Color(0xFFD9A441);
  static const Color danger = Color(0xFFB3261E);

  // Pond background gradient stops (top glow -> deep water).
  static const pondTop = Color(0xFF1FB19C);
  static const pond2 = Color(0xFF14998C);
  static const pond3 = Color(0xFF0C7C79);
  static const pond4 = Color(0xFF086566);
  static const pondDeep = Color(0xFF064F57);

  // Submerged lily-pad shadow blob (dark teal -> transparent).
  static const padShadowCore = Color(0x8C033A3C);
  static const padShadowMid = Color(0x4D044848);
  static const padShadowEdge = Color(0x00065A5A);

  // Surface ripple.
  static const ripple = Color(0x0DFFFFFF);

  // Green play lily pad.
  static const lilyGreenLight = Color(0xFF84D8AD);
  static const lilyGreenMid = Color(0xFF5CC295);
  static const lilyGreenDeep = Color(0xFF44A87E);
  static const lilyGreenStroke = Color(0xFF3C9A78);
  static const lilyGreenVein = Color(0xFF3F9D77);

  // Teal secondary lily pad.
  static const lilyTealLight = Color(0xFF33B0A0);
  static const lilyTealMid = Color(0xFF1F978B);
  static const lilyTealDeep = Color(0xFF147F78);
  static const lilyTealStroke = Color(0xFF0F6D68);

  // Progress track + lime-gold fill.
  static const progressTrack = Color(0xFF0C6160);
  static const progressTrackBorder = Color(0xFF58C2B3);
  static const progressFillStart = Color(0xFF94C92B);
  static const progressFillMid = Color(0xFFC6DD3C);
  static const progressFillEnd = Color(0xFFECEC55);
  static const progressFraction = Color(0xFFFBF1CF);

  // Chrome: settings + currency pill + plus button.
  static const settingsFill = Color(0x8C0D786E);
  static const settingsBorder = Color(0x8CBEEEE0);
  static const pillFill = Color(0x8C042A2F);
  static const pillBorder = Color(0x0FFFFFFF);
  static const pillText = Color(0xFFFDFAF0);
  static const plusButtonLight = Color(0xFF8BE3CE);
  static const plusButtonDeep = Color(0xFF58C4AD);
  static const plusButtonBorder = Color(0xB3CEF5E9);

  // Wordmark + play affordance.
  static const wordmark = Color(0xFFFDFBF3);
  static const playTriangle = Color(0xFFFBF4DC);
  static const playTriangleShadow = Color(0xFFE3D4AB);
  static const padLabel = Color(0xFFFFFFFF);
}
