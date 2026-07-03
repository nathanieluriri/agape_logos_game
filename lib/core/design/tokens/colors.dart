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

  /// Fully transparent, for surfaces that must not paint (e.g. the scaffolding
  /// behind a custom-decorated bottom sheet).
  static const Color transparent = Color(0x00000000);

  // Pond background gradient stops (top glow -> deep water).
  static const pondTop = Color(0xFF1BAFA6);
  static const pond2 = Color(0xFF12988F);
  static const pond3 = Color(0xFF0C7F80);
  static const pond4 = Color(0xFF096870);
  static const pondDeep = Color(0xFF07535F);

  // Submerged lily-pad silhouettes (flat, faintly darker than the water).
  static const ambientPadFill = Color(0x30053F44);
  static const ambientPadFillSoft = Color(0x20053F44);

  // Surface ripple.
  static const ripple = Color(0x14FFFFFF);

  // Green play lily pad.
  static const lilyGreenLight = Color(0xFF84D8AD);
  static const lilyGreenMid = Color(0xFF5CC295);
  static const lilyGreenDeep = Color(0xFF44A87E);
  static const lilyGreenUnder = Color(0xFF37946A);
  static const lilyGreenVein = Color(0xFF3F9D77);

  // Teal secondary lily pad.
  static const lilyTealLight = Color(0xFF33B0A0);
  static const lilyTealMid = Color(0xFF1F978B);
  static const lilyTealDeep = Color(0xFF147F78);
  static const lilyTealUnder = Color(0xFF0F6D68);

  // Blue bonus/secondary pad.
  static const bonusBlueLight = Color(0xFF54A9BA);
  static const bonusBlueMid = Color(0xFF3E93A6);
  static const bonusBlueDeep = Color(0xFF2F8093);
  static const bonusBlueUnder = Color(0xFF266E82);

  // Light rim glow along the top edge of every pad.
  static const padRimGlow = Color(0x8CEFFFF6);

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
  static const settingsHalo = Color(0x40BEEEE0);
  // Hairline row separator inside settings cards (settingsBorder at low alpha).
  static const rowDivider = Color(0x1FBEEEE0);
  static const settingsInnerLight = Color(0xFF2EA795);
  static const settingsInnerDeep = Color(0xFF0F7C72);
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

  /// Shadowed-water pool under the floating lotus mark (fades to clear).
  static const lotusShadow = Color(0x4D043338);
  static const padLabel = Color(0xFFFFFFFF);
  static const padLabelSoft = Color(0xD9FFFFFF);

  // Pond overlay chrome: dialog scrim, switch track, danger actions.
  static const pondScrim = Color(0xB3053F44);
  static const switchTrackOn = Color(0x8C37946A);
  static const dangerFill = Color(0x8C5C1A15);
  static const dangerBorder = Color(0x8CFFC4BC);
  static const dangerOnPond = Color(0xFFFFB4AB);

  // Game: word-forming board + wheel (approximated from the gameplay screenshots).
  static const Color tileBlue = Color(0xFF2A9FC9);
  static const Color tileBlueText = Color(0xFFFFFFFF);
  static const Color slotEmpty = Color(0xFFCBD2D8);
  static const Color wheelBase = Color(0xF2F4F7F9);
  static const Color wheelLetter = Color(0xFF1A1C1A);
  static const Color connectLine = tileBlue;
  static const Color comboBannerStart = Color(0xFF8E5BD6);
  static const Color comboBannerEnd = Color(0xFFC44FB0);

  // Game: cream wheel pad (the paper disc the letters float on).
  static const Color wheelPadLight = Color(0xFFFFFCF2);
  static const Color wheelPadMid = Color(0xFFF3ECD9);
  static const Color wheelPadDeep = Color(0xFFE6DABD);
  static const Color wheelPadUnder = Color(0xFFCFC0A0);

  // The drag line over the cream pad.
  static const Color wheelConnect = lilyGreenDeep;

  // Game: board slots, submerged hollows in the water.
  static const Color boardSlotFill = Color(0x4D053F44);
  static const Color boardSlotBorder = Color(0x2EBEEEE0);

  // Tutorial spotlight overlay.
  static const Color tutorialScrim = Color(0xE0021517);
  static const Color tutorialTrace = Color(0xD9FDFAF0);
  static const Color tutorialPillTop = Color(0xFFFFFFFF);
  static const Color tutorialPillBottom = Color(0xFFE9F0F7);

  // Brand mark (app icon + animated splash). A 2x2 grid of ivory-framed pink
  // lotus tiles with a crimson lotus-bud keystone in the top-left, and the
  // soft mint orb glow that blooms behind the assembled mark on the cream
  // splash. Sampled from the reference icon art.
  static const Color markCream = Color(0xFFFCF6EA);
  static const Color markPinkLight = Color(0xFFF9B4CC);
  static const Color markPinkMid = Color(0xFFF191B4);
  static const Color markPinkDeep = Color(0xFFE87BA6);
  static const Color markPinkEdge = Color(0xFFDD6E9C);
  static const Color markPetal = Color(0xFFFBD0E0);
  static const Color markCrimson = Color(0xFFC01F5F);
  static const Color markCrimsonDeep = Color(0xFFA5194F);
  static const Color markCrimsonPetal = Color(0xFFEE6E97);
  static const Color markGlow = Color(0x66AFE6DC);
}
