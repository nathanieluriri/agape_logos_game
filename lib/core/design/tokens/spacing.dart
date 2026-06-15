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
}
