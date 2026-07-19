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

  /// Glyph size for the icon on a secondary lily pad (Dictionary pad on Home and
  /// Level-complete). Reads well on the 104px [secondaryPad] face.
  static const double secondaryPadIcon = 28;
  static const double settingsButton = 48;
  static const double lotusWidth = 168;
  // Render width of the vector currency petal in CoinPill. The petal fills its
  // tight SVG viewBox (unlike the old padded 2 MB PNG), so this is the coin's
  // actual on-screen size, not a padded canvas width. Sized to sit on the
  // compact pill without overhanging onto neighbours.
  static const double coinPetal = 44;

  /// Inline currency-petal (`PetalIcon`) render widths. `coinPetal` (44) above
  /// is the CoinPill chip; these two are the smaller marks that replaced the old
  /// hard-coded gold dots (store balance row and item cost tag). Width only: the
  /// petal SVG viewBox (618x626) is not perfectly square, so height follows the
  /// aspect ratio and the shape never distorts.
  // PLAN: the two px values are a first pass sized up slightly from the dots
  // they replace (a petal silhouette needs a touch more width than a solid
  // circle to read). Nudge petalIconMd / petalIconSm by a point or two
  // on-device so the petal sits balanced next to the number. Keep them as
  // tokens; do not inline literals at the call sites.
  static const double petalIconMd = 22; // store balance row (was an 18px dot)
  static const double petalIconSm = 18; // inline cost tag (was a 14px dot)

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

  // Determinate loader: progress track width. Narrower than the level-complete
  // bar so it sits inside padded page bodies without overflowing on small
  // phones.
  static const double loaderTrackWidth = 220;

  /// Diameter of the blooming-lotus completion flash (LotusBloom default).
  static const double loaderBloom = 96;

  /// Backdrop blur under the fog shader, so thin mist patches read as
  /// looking through moisture. Fixed (never animated): re-recording an
  /// animated sigma every frame is the classic BackdropFilter jank.
  static const double fogBlurSigma = 7;
}
