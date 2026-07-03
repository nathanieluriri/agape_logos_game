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

  /// Estimated fill window for the determinate loading bar. The fill
  /// decelerates toward (but never claims) full while a load is in flight, so
  /// the bar keeps visibly climbing instead of sitting blank.
  static const Duration loaderRamp = Duration(milliseconds: 5200);

  /// How long a letter glides to its new slot when the wheel is shuffled.
  static const Duration shuffle = Duration(milliseconds: 340);

  /// Lifetime of a single streak confetti burst (launch + fall + fade).
  static const Duration confetti = Duration(milliseconds: 900);

  /// Lifetime of a single water-tap ripple (expand + fade).
  static const Duration ripple = Duration(milliseconds: 720);

  /// One full loop of the tutorial hand along the guided trace.
  static const Duration tutorialTrace = Duration(milliseconds: 2400);

  /// How long the tutorial's celebration pill lingers before dismissing.
  static const Duration tutorialCelebrate = Duration(milliseconds: 1600);

  /// Cold-start splash: the five blocks tumble in and bounce into place, the
  /// mark glows, and the wordmark settles before the pond is revealed.
  static const Duration splashRun = Duration(milliseconds: 1900);

  /// Reduced-motion splash: hold the finished mark briefly, then reveal.
  static const Duration splashReduced = Duration(milliseconds: 650);

  /// How long the splash overlay takes to fade away, revealing the app.
  static const Duration splashFade = Duration(milliseconds: 380);
}
