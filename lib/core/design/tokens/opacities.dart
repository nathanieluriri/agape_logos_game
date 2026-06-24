/// Opacity tokens for translucent surface overlays (scrims/glass), so widgets
/// never hardcode alpha values. Paired conceptually with [AppColors].
abstract final class AppOpacities {
  const AppOpacities._();

  /// Faintest surface tint (e.g. a pill background over a vivid gradient).
  static const double scrimLight = 0.18;

  /// Standard surface tint (e.g. a placeholder card/mark background).
  static const double scrim = 0.20;

  /// Strongest surface tint (e.g. a progress-bar track).
  static const double scrimStrong = 0.25;
}
