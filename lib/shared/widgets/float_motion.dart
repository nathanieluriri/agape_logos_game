// lib/shared/widgets/float_motion.dart
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/design/tokens/durations.dart';
import '../../core/design/tokens/elevation.dart';

/// Signature for [FloatMotion.builder]. [lift] is the pad's normalized height in
/// its bob cycle: 0 at the lowest point, 1 at the highest. Couple a pad's cast
/// shadow to [lift] (see `LilyPad.lift`) so the shadow spreads and drops as the
/// pad rises, which is what sells "floating above the water".
typedef FloatMotionBuilder = Widget Function(
  BuildContext context,
  double lift,
  Widget? child,
);

/// Wraps a child in a calm, premium, 3D-feeling float: a vertical sine bob, a
/// scale breath coupled to the bob (bigger at the top, so it reads as moving
/// toward the viewer), and an optional gentle perspective tilt on a slower,
/// phase-offset cycle. It also hands the live [lift] (0..1) to [builder] so the
/// child can couple its shadow to the bob.
///
/// One [SingleTickerProviderStateMixin] controller drives all channels so they
/// stay coherent. The controller runs the SLOW tilt cycle; the bob runs at an
/// integer number of cycles per loop ([PadElevation.tiltPeriodMultiplier]) so
/// the fast bob and slow tilt realign each loop with no slope kink at the wrap.
///
/// Reused by the play cluster (plan 05) and the multiplayer pad (plan 12): keep
/// the constructor stable (add new behaviour as optional params with defaults).
///
/// Honours reduced motion: when `MediaQuery.disableAnimations` is set, no ticker
/// runs and the child renders statically at rest, with [lift] pinned to 0 and no
/// [Transform] inserted.
class FloatMotion extends StatefulWidget {
  const FloatMotion({
    super.key,
    this.builder,
    this.amplitude = PadElevation.bobAmplitude,
    this.scaleGain = PadElevation.scaleGain,
    this.period = AppDurations.padFloat,
    this.phase = 0,
    this.tilt = true,
    this.child,
  }) : assert(
          child != null || builder != null,
          'FloatMotion needs a child, a builder, or both.',
        );

  /// Optional builder that receives the live [lift] (0..1). Use it to couple a
  /// pad shadow to the bob. When null, [child] is floated with lift fixed at 0.
  final FloatMotionBuilder? builder;

  /// Peak vertical bob travel in logical pixels (rises and falls this far from
  /// the rest line).
  final double amplitude;

  /// How much the child grows at the top of the bob (0.03 == +3%).
  final double scaleGain;

  /// Period of one full bob cycle.
  final Duration period;

  /// Phase offset as a fraction of one cycle (0..1). Give clustered pads
  /// different phases so they bob out of sync.
  final double phase;

  /// Whether to add the gentle perspective tilt.
  final bool tilt;

  /// The non-animating subtree, built once and passed back to [builder] (or
  /// floated directly when [builder] is null).
  final Widget? child;

  @override
  State<FloatMotion> createState() => _FloatMotionState();
}

class _FloatMotionState extends State<FloatMotion>
    with SingleTickerProviderStateMixin {
  // The controller runs the slow tilt period; the bob runs faster (an integer
  // number of cycles per loop) so both realign at the wrap and the loop is
  // seamless.
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.period * PadElevation.tiltPeriodMultiplier,
  );

  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _reduceMotion = reduce;
    if (reduce) {
      _c.stop();
      _c.value = 0;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    if (_reduceMotion) {
      // Static at rest: no transform, lift pinned to 0.
      return widget.builder?.call(context, 0, child) ?? child!;
    }
    return AnimatedBuilder(
      animation: _c,
      // The non-animating subtree is built once and handed back each frame.
      child: child,
      builder: (context, cachedChild) {
        final v = _c.value; // 0..1 over the controller (slow tilt) period.

        // Bob: faster than the tilt by the integer multiplier, plus the caller's
        // phase offset. A full sine so the turn-arounds are smooth.
        final bobT = (v * PadElevation.tiltPeriodMultiplier + widget.phase) *
            2 *
            math.pi;
        final bobSin = math.sin(bobT); // -1..1
        final lift = (bobSin + 1) / 2; // 0 at the bottom, 1 at the top.
        final dy = -widget.amplitude * bobSin; // up at the top of the cycle.
        final scale = 1 + widget.scaleGain * lift;

        // Tilt: one slow cycle per controller loop, 90 degrees out of phase per
        // axis so the pad gently rolls in two directions.
        const tiltRad = PadElevation.tiltDegrees * math.pi / 180;
        final slow = v * 2 * math.pi;
        final tiltX = widget.tilt ? tiltRad * math.cos(slow) : 0.0;
        final tiltY = widget.tilt ? tiltRad * math.sin(slow) : 0.0;

        // PLAN: this uses the same Matrix4 API as lily_pad.dart
        // (translateByDouble(x, y, z, w), cascade with setEntry/rotateX/
        // rotateY). scaleByDouble(sx, sy, sz, sw) is the paired 4-arg scale.
        // If the vector_math version exposes a different scale method, adjust
        // to match the one lily_pad.dart compiles against. Eyeball the tilt
        // amount on device (plan 05 Task 6).
        final matrix = Matrix4.identity()
          ..translateByDouble(0, dy, 0, 1)
          ..setEntry(3, 2, PadElevation.perspective)
          ..rotateX(tiltX)
          ..rotateY(tiltY)
          ..scaleByDouble(scale, scale, 1, 1);

        final content =
            widget.builder?.call(context, lift, cachedChild) ?? cachedChild!;
        // RepaintBoundary: isolate the pad's per-frame repaint from the pond.
        return RepaintBoundary(
          child: Transform(
            alignment: Alignment.center,
            transform: matrix,
            child: content,
          ),
        );
      },
    );
  }
}
