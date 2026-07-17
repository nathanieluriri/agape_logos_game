// lib/core/design/tokens/gradients.dart
import 'package:flutter/widgets.dart';
import 'colors.dart';

/// Gradient tokens for the pond theme. Single source of truth: widgets
/// reference these instead of building gradients inline.
abstract final class AppGradients {
  const AppGradients._();

  /// Full-viewport pond: a top glow easing into deep teal water.
  /// Mirrors the reference radial glow with a top-anchored center.
  static const pond = RadialGradient(
    center: Alignment(0, -0.48),
    radius: 1.2,
    colors: [
      AppColors.pondTop,
      AppColors.pond2,
      AppColors.pond3,
      AppColors.pond4,
      AppColors.pondDeep,
    ],
    stops: [0.0, 0.34, 0.60, 0.82, 1.0],
  );

  /// Dialog/sheet card surface: a vertical wash from mid to deep pond water.
  static const pondCard = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.pond3, AppColors.pondDeep],
  );

  /// Lime to gold progress fill (left to right).
  static const progressFill = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      AppColors.progressFillStart,
      AppColors.progressFillMid,
      AppColors.progressFillEnd,
    ],
    stops: [0.0, 0.55, 1.0],
  );

  /// Premium fill for the shared progress track: the lime-gold base with a lit
  /// crest at the leading (right) edge so the fill visibly pushes its rider.
  static const progressFillPremium = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      AppColors.progressFillStart,
      AppColors.progressFillMid,
      AppColors.progressFillEnd,
      AppColors.progressFillCrest,
    ],
    stops: [0.0, 0.5, 0.86, 1.0],
  );

  /// Glossy top-surface highlight over the fill: bright at the top, clear by
  /// mid-height, so the fill reads as a lit water surface rather than flat paint.
  static const progressGloss = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.progressGlossHighlight, Color(0x00FFFFFF)],
    stops: [0.0, 0.55],
  );

  /// A soft sheen band swept left-to-right along the fill for a shimmer pass.
  /// Transparent, peaking at the centre, transparent again.
  static const progressSheen = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0x00FFFFFF), AppColors.progressSheenPeak, Color(0x00FFFFFF)],
    stops: [0.15, 0.5, 0.85],
  );

  /// Blooming-lotus flash for a determinate completion or a full clear: a warm
  /// lime-gold core fading to clear.
  static const loaderBloom = RadialGradient(
    colors: [AppColors.loaderBloomCore, Color(0x00F2F7C4)],
  );

  /// Green play lily pad sheen (top-left light source).
  static const lilyGreen = RadialGradient(
    center: Alignment(-0.24, -0.36),
    radius: 0.95,
    colors: [
      AppColors.lilyGreenLight,
      AppColors.lilyGreenMid,
      AppColors.lilyGreenDeep,
    ],
    stops: [0.0, 0.55, 1.0],
  );

  /// Teal secondary lily pad sheen.
  static const lilyTeal = RadialGradient(
    center: Alignment(-0.24, -0.36),
    radius: 0.95,
    colors: [
      AppColors.lilyTealLight,
      AppColors.lilyTealMid,
      AppColors.lilyTealDeep,
    ],
    stops: [0.0, 0.55, 1.0],
  );

  /// Blue bonus circle sheen (top-left light source).
  static const bonusBlue = RadialGradient(
    center: Alignment(-0.24, -0.36),
    radius: 0.95,
    colors: [
      AppColors.bonusBlueLight,
      AppColors.bonusBlueMid,
      AppColors.bonusBlueDeep,
    ],
    stops: [0.0, 0.55, 1.0],
  );

  /// Coral multiplayer lily pad sheen (top-left light source), matching the
  /// green/teal/blue pad language.
  static const lilyCoral = RadialGradient(
    center: Alignment(-0.24, -0.36),
    radius: 0.95,
    colors: [
      AppColors.lilyCoralLight,
      AppColors.lilyCoralMid,
      AppColors.lilyCoralDeep,
    ],
    stops: [0.0, 0.55, 1.0],
  );

  /// Cream wheel pad sheen (top-left light source): the paper disc the
  /// letter wheel floats on.
  static const wheelPad = RadialGradient(
    center: Alignment(-0.24, -0.36),
    radius: 0.95,
    colors: [
      AppColors.wheelPadLight,
      AppColors.wheelPadMid,
      AppColors.wheelPadDeep,
    ],
    stops: [0.0, 0.55, 1.0],
  );

  /// Soft oval pool of shadowed water under the floating lotus mark.
  static const lotusShadow = RadialGradient(
    colors: [AppColors.lotusShadow, Color(0x00043338)],
  );

  /// Round plus button.
  static const plusButton = RadialGradient(
    center: Alignment(-0.24, -0.36),
    radius: 0.9,
    colors: [AppColors.plusButtonLight, AppColors.plusButtonDeep],
  );

  /// Settings button inner disc.
  static const settingsInner = RadialGradient(
    center: Alignment(-0.24, -0.36),
    radius: 0.95,
    colors: [AppColors.settingsInnerLight, AppColors.settingsInnerDeep],
  );

  /// Light rim glow, brightest at the top edge, fading out by two-thirds
  /// down. Stroked along the pad outline.
  static const padRimGlow = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.padRimGlow, Color(0x00FFFFFF)],
    stops: [0.0, 0.66],
  );

  /// Tutorial coach pill: a light paper wash, white easing into a cool grey.
  static const tutorialPill = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.tutorialPillTop, AppColors.tutorialPillBottom],
  );

  /// Pink lotus-tile sheen for the brand mark (top-left light source, the same
  /// language as the lily pads).
  static const markPane = RadialGradient(
    center: Alignment(-0.24, -0.36),
    radius: 0.98,
    colors: [
      AppColors.markPinkLight,
      AppColors.markPinkMid,
      AppColors.markPinkDeep,
    ],
    stops: [0.0, 0.55, 1.0],
  );

  /// Crimson lotus-bud keystone sheen.
  static const markBud = RadialGradient(
    center: Alignment(-0.2, -0.3),
    radius: 0.95,
    colors: [
      AppColors.markCrimsonPetal,
      AppColors.markCrimson,
      AppColors.markCrimsonDeep,
    ],
    stops: [0.0, 0.5, 1.0],
  );

  /// Soft mint halo that blooms behind the assembled mark on the cream splash.
  /// Fades from a translucent mint core to fully clear.
  static const splashGlow = RadialGradient(
    colors: [AppColors.markGlow, Color(0x00AFE6DC)],
  );
}
