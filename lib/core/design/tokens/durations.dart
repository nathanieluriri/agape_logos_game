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
}
