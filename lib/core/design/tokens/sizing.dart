// lib/core/design/tokens/sizing.dart
/// Layout size tokens. Single source of truth for component dimensions that
/// are not part of the 4-point spacing scale.
abstract final class AppSizing {
  const AppSizing._();

  /// Max width of the centered portrait stage on wide/web viewports.
  static const double stageMaxWidth = 460;

  static const double playPad = 180;
  static const double playAreaHeight = 240;
  static const double secondaryPad = 104;
  static const double settingsButton = 48;
  static const double lotusWidth = 168;
  static const double coinPetal = 34;

  static const double progressTrackWidth = 300;
  static const double progressTrackHeight = 22;

  // Game: letter wheel + board tiles.
  static const double wheelDiameter = 260;
  static const double wheelNode = 56;
  static const double boardTile = 44;
  static const double boardTileGap = 8;
}
