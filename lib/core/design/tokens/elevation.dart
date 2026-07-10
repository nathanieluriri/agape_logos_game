/// How a lily pad behaves when it floats and lifts off the water: the bob
/// kinematics consumed by [FloatMotion] and the cast-shadow response consumed
/// by the LilyPad painter. Kept in one place so these numbers are tunable
/// together rather than scattered inline in widgets.
///
/// At `lift == 0` the shadow-response fields below are all no-ops, so a static
/// pad paints exactly as it did before this system existed (golden-stable).
abstract final class PadElevation {
  const PadElevation._();

  // --- FloatMotion kinematics ---

  /// Peak vertical bob travel, logical pixels. The pad rises and falls this far
  /// from its rest line. Matches the pre-overhaul play-pad float.
  // PLAN: tune on device. ~5..8 is the calm band; higher starts to look floaty
  // rather than premium.
  static const double bobAmplitude = 7;

  /// How much a pad grows at the top of its bob (0.03 == +3%). Reads as a gentle
  /// move toward the viewer, which is what makes the bob feel dimensional.
  // PLAN: tune on device. Keep <= ~0.04; more looks like a pulse, not depth.
  static const double scaleGain = 0.03;

  /// Peak perspective tilt on each axis, degrees. A few degrees only.
  // PLAN: tune on device. 2..3.5 reads as "resting on water"; more looks wobbly.
  static const double tiltDegrees = 2.5;

  /// Perspective foreshortening for the tilt (Matrix4 entry (3, 2)).
  static const double perspective = 0.001;

  /// The tilt runs this many times slower than the bob. Integer on purpose: the
  /// bob and the tilt then realign every controller loop, so the animation has
  /// no slope kink at the wrap point.
  static const int tiltPeriodMultiplier = 2;

  /// Phase offsets (fraction of one bob cycle, 0..1) for the two clustered pads
  /// so they bob out of sync and the cluster reads as two separate objects.
  static const double playPhase = 0;
  static const double secondaryPhase = 0.5;

  // --- Cast-shadow response to lift (consumed by the LilyPad painter) ---
  // As the pad rises (lift 0 -> 1) its shadow grows and softens, drops further,
  // and fades. This decoupling of the shadow from the pad body is the single
  // biggest "floating above water" cue.

  /// Extra blur as a fraction of the base pad-shadow blur (0.6 == +60% at full
  /// lift). Larger + softer shadow reads as "further from the surface".
  // PLAN: tune on device alongside `shadowDrop`.
  static const double shadowBlurGain = 0.6;

  /// Extra downward offset added to the base shadow at full lift, logical
  /// pixels. Set roughly to the bob travel so the shadow appears to stay on the
  /// water while the pad rises above it (the pad body translates up by the bob;
  /// this pushes the shadow back down toward the surface).
  // PLAN: tune on device so the shadow looks pinned to the water, not glued to
  // the pad. Start near 2x `bobAmplitude`.
  static const double shadowDrop = 12;

  /// How much the shadow fades at full lift (0.35 == down to 65% opacity).
  // PLAN: tune on device. Too much fade makes the pad look detached.
  static const double shadowFade = 0.35;

  // --- Ambient submerged-pad breath (consumed by PadShadowComponent) ---
  // Subtle depth wobble for the Flame background pads, out of phase with drift.

  /// Angular frequency multiplier applied to the drift phase for the breath.
  static const double ambientBreatheFreq = 0.7;

  /// Peak size swell of an ambient pad (0.04 == +/-4%).
  static const double ambientScaleGain = 0.04;

  /// Peak opacity dip of an ambient pad as it swells (0.25 == down to 75%).
  static const double ambientOpacityGain = 0.25;
}
