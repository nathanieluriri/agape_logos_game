// lib/core/design/tokens/sizing.dart
/// Layout size tokens. Single source of truth for component dimensions that
/// are not part of the 4-point spacing scale.
abstract final class AppSizing {
  const AppSizing._();

  /// Max width of the centered portrait stage on wide/web viewports.
  static const double stageMaxWidth = 460;

  static const double playPad = 180;
  static const double secondaryPad = 104;
  static const double settingsButton = 48;
  static const double lotusWidth = 168;
  static const double coinPetal = 34;

  static const double progressTrackWidth = 300;
  static const double progressTrackHeight = 22;
}
