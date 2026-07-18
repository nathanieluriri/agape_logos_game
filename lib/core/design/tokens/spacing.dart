/// 4-point spacing scale - the single source of truth for layout spacing.
///
/// No raw padding/margin numbers in widgets; reference these tokens.
abstract final class AppSpacing {
  const AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Top inset the incoming-powerup banner rests at once it has dropped in.
  static const double powerupBannerTopInset = 72;

  /// Vertical travel distance of the incoming-powerup banner's drop-in glide,
  /// from just above the screen down to [powerupBannerTopInset].
  static const double powerupBannerDropDistance = 160;

  /// Diameter of the drawing app mark on the match interlude screen.
  static const double matchInterludeMarkSize = 160;
}
