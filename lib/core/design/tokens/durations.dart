/// Motion timing tokens.
///
/// All animation and screen-transition durations reference these so motion
/// stays consistent and tunable from one place.
abstract final class AppDurations {
  const AppDurations._();

  static const Duration instant = Duration(milliseconds: 90);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 450);

  /// Lifetime of a single water-tap ripple (expand + fade).
  static const Duration ripple = Duration(milliseconds: 720);

  /// One full loop of the tutorial hand along the guided trace.
  static const Duration tutorialTrace = Duration(milliseconds: 2400);

  /// How long the tutorial's celebration pill lingers before dismissing.
  static const Duration tutorialCelebrate = Duration(milliseconds: 1600);
}
