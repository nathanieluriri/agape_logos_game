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
  static const double coinPetal = 56;

  static const double progressTrackWidth = 300;
  static const double progressTrackHeight = 22;

  // Game: letter wheel + board tiles.
  static const double wheelDiameter = 260;
  static const double wheelNode = 56;
  static const double boardTile = 44;
  static const double boardTileGap = 8;

  static const double actionButton = 56;
  static const double topBarButton = 44;
  static const double comboBannerHeight = 52;
  static const double pillHeight = 40;

  // Tutorial spotlight overlay: pointing hand, cutout breathing room, pill.
  static const double tutorialHand = 64;
  static const double tutorialCutoutPad = 12;
  static const double tutorialPillMaxWidth = 340;

  // Pond control primitives: switch, capsule button, loader, dialog.
  static const double switchTrackWidth = 58;
  static const double switchTrackHeight = 34;
  static const double switchKnob = 26;
  static const double pillButtonHeight = 44;
  static const double loader = 48;
  static const double dialogMaxWidth = 360;
}
