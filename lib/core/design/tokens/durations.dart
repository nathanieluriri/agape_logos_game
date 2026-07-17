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

  /// One full bob cycle of a floating lily pad (FloatMotion). Slow and calm so
  /// the pond reads as premium and unhurried, not busy.
  // PLAN: tune on device. Longer (up to ~3800ms) reads calmer; shorter reads
  // more alive. Keep it well above `slow` so the motion never feels twitchy.
  static const Duration padFloat = Duration(milliseconds: 3200);

  /// Estimated fill window for the determinate loading bar. The fill
  /// decelerates toward (but never claims) full while a load is in flight, so
  /// the bar keeps visibly climbing instead of sitting blank.
  static const Duration loaderRamp = Duration(milliseconds: 5200);

  /// One pass of the sheen band sweeping along a progress fill.
  static const Duration progressShimmer = Duration(milliseconds: 1500);

  /// One full bob-and-tilt cycle of the petal riding the loader fill crest.
  static const Duration petalBob = Duration(milliseconds: 1600);

  /// Full span of the indeterminate trickle: one forward-only run of the
  /// loader controller. The asymptotic fill has flattened near its ceiling
  /// long before this elapses; afterwards the fill simply holds (the sheen
  /// keeps sweeping, so the loader still reads as alive).
  static const Duration loaderTrickleSpan = Duration(seconds: 20);

  /// Time constant of the indeterminate trickle: the fill covers ~63% of the
  /// remaining distance to its ceiling every interval of this length, so it
  /// starts briskly and visibly decelerates the longer a request takes.
  static const Duration loaderTrickleTau = Duration(milliseconds: 1600);

  /// The blooming-lotus pop when a determinate loader reaches 1.0 (also the
  /// level-complete full-clear bloom).
  static const Duration bloomPop = Duration(milliseconds: 640);

  /// How long a letter glides to its new slot when the wheel is shuffled.
  static const Duration shuffle = Duration(milliseconds: 340);

  /// Per-tile delay in the word-board fill cascade: each tile of a found word
  /// begins its reveal this long after the tile to its left, giving the row a
  /// left-to-right wave instead of every cell popping on the same frame.
  // PLAN: tileStagger (~55-70ms) and tileReveal (~260ms) are the two knobs to
  // tune on-device: raise tileStagger for a more pronounced wave, lower it if
  // a long word feels slow. Total cascade for an N-letter word is
  // tileStagger * (N - 1) + tileReveal; keep a 7-letter word under ~650ms.
  static const Duration tileStagger = Duration(milliseconds: 60);

  /// How long a single board tile takes to bloom from an empty slot into a
  /// filled lily pad (pad scale-in + lift + glyph pop), excluding any leading
  /// stagger delay.
  static const Duration tileReveal = Duration(milliseconds: 260);

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

  /// One full loop of the animated app mark: the rim traces, the icon wipes in
  /// behind it, the halo blooms, and it settles back to the start.
  static const Duration markDraw = Duration(milliseconds: 2600);

  /// A fired powerup chip scaling up and flying off the top edge (the
  /// caster's half of the cast feedback loop).
  static const Duration powerupCast = Duration(milliseconds: 600);

  /// How long the incoming-powerup banner holds at center, after dropping in
  /// and before flying away, so "{caster} cast {powerup}!" has time to read.
  static const Duration powerupBannerHold = Duration(milliseconds: 1500);

  /// The fog front rolling down over the board (and lifting back out).
  static const Duration fogRoll = Duration(milliseconds: 2500);

  /// A powerup's land animation on the board (frost creep, shield bloom,
  /// ward sweep, aura ignite).
  static const Duration effectLand = Duration(milliseconds: 600);

  /// A timed effect's expiry animation (ice shatter, ward dissolve,
  /// shield pop).
  static const Duration effectExpire = Duration(milliseconds: 400);

  /// The scramble swirl: letters lift, loop the wheel once, and settle.
  static const Duration scrambleSwirl = Duration(milliseconds: 900);

  /// A stolen word's flight off the board (victim) or into the score
  /// (caster).
  static const Duration stealFlight = Duration(milliseconds: 800);

  /// The match timer digits rolling up to the boosted deadline.
  static const Duration timeBoostClimb = Duration(milliseconds: 800);
}
