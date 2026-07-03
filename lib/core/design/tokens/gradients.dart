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
