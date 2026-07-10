import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/motion/curves.dart';
import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/durations.dart';
import '../../core/haptics/haptics.dart';

/// Where the ripple is born: a droplet a touch below the screen's centre, so
/// the new screen feels like it wells up from the pond / play area rather than
/// from a neutral middle point.
const Alignment _dropletOrigin = Alignment(0, 0.35);

/// Shared animated page builder - every screen transition runs through motion
/// tokens, so navigation always feels game-like and stays tunable in one place.
///
/// Bespoke, on-theme motion in three blended layers:
///
/// 1. The incoming screen is revealed by a circular water ripple spreading
///    from a droplet point - but instead of a hard clip, the reveal edge is a
///    feathered alpha gradient, so the new screen *dissolves* into view along
///    a soft waterline rather than being sliced in.
/// 2. The incoming content settles from a whisper of extra scale down to
///    rest, as if the surface is still moving when it first appears; a couple
///    of foam rings ride the leading edge (the same pond-ripple language as
///    the app-wide tap ripple), with one faint anticipation ring running just
///    ahead of the waterline over the old screen.
/// 3. The outgoing screen doesn't sit frozen underneath: it gently sinks -
///    scaling down a few percent and dimming under a deep-water tint - so the
///    two screens read as one continuous body of water.
///
/// Pops run everything in reverse (the ripple drains back to the droplet
/// while the screen below rises to the surface). The close is quicker than
/// the open - going back should feel light - but unhurried enough
/// ([AppDurations.normal], easing in) that the drain reads as motion rather
/// than a blink. Collapses to an instant cut when the platform requests
/// reduced motion. Once a transition completes, the builders return the bare
/// child, so settled screens pay zero compositing cost.
/// Skips the landing tick for the very first page (cold boot), so launch is silent.
bool _navHapticsPrimed = false;

CustomTransitionPage<T> pondRevealPage<T>(Widget child, GoRouterState state) {
  // A soft "landed" tick as the new screen wells up. Fired once per navigation
  // (this factory runs once per route resolution, not per animation frame), and
  // lighter than the tapped button so it does not double up as a second click.
  // PLAN: do NOT move the haptic into transitionsBuilder (it runs every frame).
  // If the double cue (tap buzz + landing tick) feels like too much on device,
  // drop this tick; the button taps already cover navigation.
  if (_navHapticsPrimed) {
    Haptics.instance.tickImpact();
  } else {
    _navHapticsPrimed = true;
  }
  return CustomTransitionPage<T>(
    key: state.pageKey,
    transitionDuration: AppDurations.slow,
    reverseTransitionDuration: AppDurations.normal,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // NOTE: this builder re-runs on every animation tick, so it must not
      // allocate listener-registering objects (e.g. CurvedAnimation) here;
      // the stateful widgets below own their curves and dispose them.
      final reduceMotion =
          MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      if (reduceMotion) return child;
      return _PondSink(
        animation: secondaryAnimation,
        child: _PondReveal(animation: animation, child: child),
      );
    },
  );
}

/// Longest distance from [origin] to any corner of [size]: the radius the
/// ripple must reach to cover the screen.
double _coverRadius(Offset origin, Size size) {
  final dx = math.max(origin.dx, size.width - origin.dx);
  final dy = math.max(origin.dy, size.height - origin.dy);
  return math.sqrt(dx * dx + dy * dy);
}

/// Reveals [child] through a feather-edged circular alpha mask that grows
/// from the droplet origin, while the content settles from a hint of extra
/// scale and foam rings ride the waterline. Rebuilds once per frame off the
/// transition [animation]; returns the bare child once fully revealed.
///
/// Stateful only so the [CurvedAnimation] is created once and disposed with
/// the route, instead of leaking a status listener per frame.
class _PondReveal extends StatefulWidget {
  const _PondReveal({required this.animation, required this.child});

  /// The route's raw transition animation (curved internally).
  final Animation<double> animation;
  final Widget child;

  /// Fraction of the transition over which the newborn droplet fades from
  /// nothing to fully opaque, so the reveal materialises instead of popping.
  static const double _materialiseWindow = 0.15;

  /// Extra scale the incoming screen carries at t = 0, easing to rest at 1.
  /// Overscan only (never < 1), so screen edges can't peek through the mask.
  static const double _settleOverscan = 0.035;

  /// Width of the soft alpha edge, as a fraction of the current ripple
  /// radius, clamped so the droplet stays dewy and the final sweep stays
  /// water-soft without washing out the whole screen.
  static const double _featherFraction = 0.22;
  static const double _featherMin = 28;
  static const double _featherMax = 110;

  @override
  State<_PondReveal> createState() => _PondRevealState();
}

class _PondRevealState extends State<_PondReveal> {
  late CurvedAnimation _curve;

  CurvedAnimation _newCurve() => CurvedAnimation(
        parent: widget.animation,
        curve: AppCurves.enter,
        reverseCurve: AppCurves.exit,
      );

  @override
  void initState() {
    super.initState();
    _curve = _newCurve();
  }

  @override
  void didUpdateWidget(_PondReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      _curve.dispose();
      _curve = _newCurve();
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) {
        final t = _curve.value;
        // Settled: no mask, no painter, no saveLayer - just the screen.
        if (t >= 1) return child!;
        return CustomPaint(
          foregroundPainter: _RippleEdgePainter(t),
          child: ShaderMask(
            shaderCallback: (bounds) => _revealShader(bounds, t),
            blendMode: BlendMode.dstIn,
            child: Transform.scale(
              scale: 1 + _PondReveal._settleOverscan * (1 - t),
              alignment: _dropletOrigin,
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// Radial alpha gradient: fully opaque out to the ripple edge, feathering
  /// to transparent beyond it, with the whole mask ramping up over
  /// [_PondReveal._materialiseWindow] so the first frames well up instead of
  /// blinking in.
  ui.Shader _revealShader(Rect bounds, double t) {
    final size = bounds.size;
    final origin = _dropletOrigin.alongSize(size);
    final edge = _coverRadius(origin, size) * t;
    final feather = (edge * _PondReveal._featherFraction)
        .clamp(_PondReveal._featherMin, _PondReveal._featherMax)
        .toDouble();
    final outer = math.max(edge + feather, 1.0);
    final ramp =
        (t / _PondReveal._materialiseWindow).clamp(0.0, 1.0).toDouble();
    final solid = AppColors.maskSolid.withValues(alpha: ramp);
    return ui.Gradient.radial(
      origin,
      outer,
      [solid, solid, AppColors.transparent],
      [0, (edge / outer).clamp(0.0, 1.0).toDouble(), 1],
    );
  }
}

/// The screen *underneath* a running ripple: sinks a few percent in scale and
/// dims under a deep-water tint while the new screen spreads over it, then
/// rises back on pop. Driven by the route's secondary animation; returns the
/// bare child whenever nothing is happening above it.
///
/// Stateful only so the [CurvedAnimation] is created once and disposed with
/// the route, instead of leaking a status listener per frame.
class _PondSink extends StatefulWidget {
  const _PondSink({required this.animation, required this.child});

  /// The route's raw secondary animation (curved internally).
  final Animation<double> animation;
  final Widget child;

  /// Scale the outgoing screen sinks to at full submersion.
  static const double _sunkScale = 0.965;

  /// Peak opacity of the deep-water tint laid over the sinking screen.
  static const double _tintOpacity = 0.22;

  @override
  State<_PondSink> createState() => _PondSinkState();
}

class _PondSinkState extends State<_PondSink> {
  late CurvedAnimation _curve;

  CurvedAnimation _newCurve() =>
      CurvedAnimation(parent: widget.animation, curve: AppCurves.float);

  @override
  void initState() {
    super.initState();
    _curve = _newCurve();
  }

  @override
  void didUpdateWidget(_PondSink oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      _curve.dispose();
      _curve = _newCurve();
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) {
        final s = _curve.value;
        // On top of the stack and undisturbed: zero added cost.
        if (s <= 0) return child!;
        // Opaque deep water *behind* the shrinking screen, so the few pixels
        // it pulls away from the window edges read as pond, not as a bare
        // window surface flickering through.
        return ColoredBox(
          color: AppColors.pondDeep,
          child: Transform.scale(
            scale: 1 - (1 - _PondSink._sunkScale) * s,
            alignment: _dropletOrigin,
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                child!,
                Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(
                      color: AppColors.pondDeep
                          .withValues(alpha: _PondSink._tintOpacity * s),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Foam rings around the reveal waterline. Painted *outside* the alpha mask,
/// so the crest can straddle the soft edge and one faint anticipation ring
/// can run ahead of it, over the outgoing screen.
class _RippleEdgePainter extends CustomPainter {
  const _RippleEdgePainter(this.fraction);

  final double fraction;

  /// Trailing rings behind the crest; their spacing (logical px) widens as
  /// the wave travels, the way real ripples disperse.
  static const int _trailingRings = 2;
  static const double _gapBase = 18;
  static const double _gapGrowth = 26;

  @override
  void paint(Canvas canvas, Size size) {
    if (fraction <= 0 || fraction >= 1) return;
    final origin = _dropletOrigin.alongSize(size);
    final edge = _coverRadius(origin, size) * fraction;
    // Rings are strongest early and fade out as the ripple fills the screen.
    final fade = 1 - fraction;
    final gap = _gapBase + _gapGrowth * fraction;

    Paint stroke(Color color, double alpha, double width) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..color = color.withValues(alpha: alpha);

    // Light foam crest riding the waterline itself.
    canvas.drawCircle(
      origin,
      edge,
      stroke(AppColors.padRimGlow, fade * 0.5, 2.5),
    );

    // Faint anticipation ring ahead of the crest, over the outgoing screen.
    canvas.drawCircle(
      origin,
      edge + gap * 0.8,
      stroke(AppColors.padRimGlow, fade * 0.12, 2),
    );

    // Trailing rings settling behind the wave, over the incoming screen.
    for (var i = 0; i < _trailingRings; i++) {
      final radius = edge - (i + 1) * gap;
      if (radius <= 0) continue;
      canvas.drawCircle(
        origin,
        radius,
        stroke(AppColors.wheelConnect, fade * (0.35 - i * 0.15), 2.0 - i * 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(_RippleEdgePainter oldDelegate) =>
      oldDelegate.fraction != fraction;
}
