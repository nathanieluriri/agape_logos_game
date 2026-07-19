import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/motion/curves.dart';
import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/durations.dart';
import '../../core/haptics/haptics.dart';

/// Where the ripple is born: a droplet a touch below the screen's centre, so
/// the new screen feels like it surfaces from the pond / play area rather than
/// from a neutral middle point.
const Alignment _dropletOrigin = Alignment(0, 0.35);

/// Fraction of the transition given to the outgoing screen's dive. The
/// incoming screen only starts surfacing after this point, so the two screens
/// are never on screen together: the pond itself (the shared shell behind
/// every page) is what fills the hand-off beat. Weighted like a breath,
/// a quick dip under, a longer rise back out.
const double _handoff = 0.35;

/// Shared animated page builder - every screen transition runs through motion
/// tokens, so navigation always feels game-like and stays tunable in one place.
///
/// Screens pass *through the water*, never over each other:
///
/// 1. The outgoing screen dives: over the first [_handoff] of the transition
///    it sinks a few pixels, draws in toward the droplet point, and fades to
///    nothing.
/// 2. For a beat at the hand-off only the pond is on screen - the living
///    shell behind every page, pads still drifting - so the water reads as
///    the medium the screens move through, not a backdrop they slide over.
/// 3. The incoming screen surfaces through the rest: rising from a touch
///    below, settling from a whisper under rest scale, and fading in while
///    foam rings sweep outward from the droplet point.
///
/// Pops run the same story back (the top screen dives away, the screen below
/// rises to the surface), quicker ([AppDurations.normal]) so going back feels
/// light. Collapses to an instant cut when the platform requests reduced
/// motion.
///
/// The wrappers keep ONE stable widget tree for the whole ride: at rest every
/// layer is a no-op (opacity 1 paints straight through with no layer, identity
/// transforms, an early-out painter), so settled screens pay nothing and the
/// page subtree is never reparented mid-flight or at settle.
/// Skips the landing tick for the very first page (cold boot), so launch is silent.
bool _navHapticsPrimed = false;

CustomTransitionPage<T> pondRevealPage<T>(Widget child, GoRouterState state) {
  // A soft "landed" tick as the new screen surfaces. Fired once per navigation
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
      return _PondDive(
        animation: secondaryAnimation,
        child: _PondSurface(animation: animation, child: child),
      );
    },
  );
}

/// Longest distance from [origin] to any corner of [size]: the radius the
/// foam rings must reach to sweep the whole screen.
double _coverRadius(Offset origin, Size size) {
  final dx = math.max(origin.dx, size.width - origin.dx);
  final dy = math.max(origin.dy, size.height - origin.dy);
  return math.sqrt(dx * dx + dy * dy);
}

/// The incoming screen surfacing out of the pond: invisible until the
/// outgoing screen's dive has finished, then rising, settling, and fading in
/// while foam rings ripple outward.
///
/// Stateful only so the [CurvedAnimation] is created once and disposed with
/// the route, instead of leaking a status listener per frame.
class _PondSurface extends StatefulWidget {
  const _PondSurface({required this.animation, required this.child});

  /// The route's raw transition animation (curved internally).
  final Animation<double> animation;
  final Widget child;

  /// How far below its resting place the surfacing screen starts (logical px).
  static const double _rise = 26;

  /// Scale the surfacing screen grows from as it settles at the surface.
  static const double _settleFrom = 0.97;

  @override
  State<_PondSurface> createState() => _PondSurfaceState();
}

class _PondSurfaceState extends State<_PondSurface> {
  late CurvedAnimation _curve;

  CurvedAnimation _newCurve() => CurvedAnimation(
    parent: widget.animation,
    curve: const Interval(_handoff, 1, curve: AppCurves.enter),
    reverseCurve: const Interval(_handoff, 1, curve: AppCurves.exit),
  );

  @override
  void initState() {
    super.initState();
    _curve = _newCurve();
  }

  @override
  void didUpdateWidget(_PondSurface oldWidget) {
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
      child: RepaintBoundary(child: widget.child),
      builder: (context, child) {
        final t = _curve.value.clamp(0.0, 1.0);
        // One stable tree for the whole ride. At t = 0 the opacity layer
        // skips painting entirely (the pond alone shows); at t = 1 opacity
        // paints straight through with no layer and the transforms are
        // identity, so a settled screen pays nothing.
        return CustomPaint(
          foregroundPainter: _RippleEdgePainter(t),
          child: Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, _PondSurface._rise * (1 - t)),
              child: Transform.scale(
                scale: _PondSurface._settleFrom +
                    (1 - _PondSurface._settleFrom) * t,
                alignment: _dropletOrigin,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The outgoing screen diving beneath the surface: over the first [_handoff]
/// of the transition it sinks, draws in toward the droplet point, and fades
/// to nothing, leaving only the pond behind. Driven by the route's secondary
/// animation; rises back the same way on pop.
///
/// Stateful only so the [CurvedAnimation] is created once and disposed with
/// the route, instead of leaking a status listener per frame.
class _PondDive extends StatefulWidget {
  const _PondDive({required this.animation, required this.child});

  /// The route's raw secondary animation (curved internally).
  final Animation<double> animation;
  final Widget child;

  /// Scale the diving screen shrinks to as it slips under.
  static const double _dipScale = 0.965;

  /// How far the diving screen drifts down as it goes (logical px).
  static const double _drop = 14;

  @override
  State<_PondDive> createState() => _PondDiveState();
}

class _PondDiveState extends State<_PondDive> {
  late CurvedAnimation _curve;

  CurvedAnimation _newCurve() => CurvedAnimation(
    parent: widget.animation,
    curve: const Interval(0, _handoff, curve: AppCurves.exit),
  );

  @override
  void initState() {
    super.initState();
    _curve = _newCurve();
  }

  @override
  void didUpdateWidget(_PondDive oldWidget) {
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
      child: RepaintBoundary(child: widget.child),
      builder: (context, child) {
        final s = _curve.value.clamp(0.0, 1.0);
        // Same stable-tree discipline as _PondSurface: no-op at s = 0
        // (undisturbed on top of the stack), skips painting at s = 1
        // (fully under while another screen surfaces above the pond).
        return Opacity(
          opacity: 1 - s,
          child: Transform.translate(
            offset: Offset(0, _PondDive._drop * s),
            child: Transform.scale(
              scale: 1 - (1 - _PondDive._dipScale) * s,
              alignment: _dropletOrigin,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Foam rings sweeping outward from the droplet point while the incoming
/// screen surfaces: the splash that announces it, strongest as it breaks the
/// surface and dissolving as it settles.
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
    // Rings are strongest early and fade out as the wave fills the screen.
    final fade = 1 - fraction;
    final gap = _gapBase + _gapGrowth * fraction;

    Paint stroke(Color color, double alpha, double width) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..color = color.withValues(alpha: alpha);

    // Light foam crest riding the wavefront.
    canvas.drawCircle(
      origin,
      edge,
      stroke(AppColors.padRimGlow, fade * 0.5, 2.5),
    );

    // Faint anticipation ring running ahead of the crest.
    canvas.drawCircle(
      origin,
      edge + gap * 0.8,
      stroke(AppColors.padRimGlow, fade * 0.12, 2),
    );

    // Trailing rings settling behind the wave, over the surfacing screen.
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
