import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/motion/curves.dart';
import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/durations.dart';

/// Where the ripple is born: a droplet a touch below the screen's centre, so
/// the new screen feels like it wells up from the pond / play area rather than
/// from a neutral middle point.
const Alignment _dropletOrigin = Alignment(0, 0.35);

/// Shared animated page builder - every screen transition runs through motion
/// tokens, so navigation always feels game-like and stays tunable in one place.
///
/// Bespoke, on-theme motion: the incoming screen is revealed by a circular
/// water ripple that spreads from a droplet point, with a couple of soft rings
/// riding the leading edge (the same pond-ripple language as the app-wide tap
/// ripple). Pops run it in reverse, closing the ripple back to the droplet.
/// Collapses to an instant cut when the platform requests reduced motion.
CustomTransitionPage<T> pondRevealPage<T>(Widget child, GoRouterState state) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    transitionDuration: AppDurations.slow,
    reverseTransitionDuration: AppDurations.fast,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (reduceMotion) return child;
      return _PondReveal(
        animation: CurvedAnimation(parent: animation, curve: AppCurves.enter),
        child: child,
      );
    },
  );
}

/// Clips [child] to a growing circle and rides the reveal edge with fading
/// ripple rings. Rebuilds once per frame off the transition [animation].
class _PondReveal extends StatelessWidget {
  const _PondReveal({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = animation.value;
        return ClipPath(
          clipper: _RippleClipper(t),
          child: CustomPaint(
            foregroundPainter: _RippleEdgePainter(t),
            child: child,
          ),
        );
      },
    );
  }
}

/// Longest distance from [origin] to any corner of [size]: the radius the
/// ripple must reach to cover the screen.
double _coverRadius(Offset origin, Size size) {
  final dx = math.max(origin.dx, size.width - origin.dx);
  final dy = math.max(origin.dy, size.height - origin.dy);
  return math.sqrt(dx * dx + dy * dy);
}

class _RippleClipper extends CustomClipper<Path> {
  const _RippleClipper(this.fraction);

  final double fraction;

  @override
  Path getClip(Size size) {
    final origin = _dropletOrigin.alongSize(size);
    final radius = _coverRadius(origin, size) * fraction;
    return Path()..addOval(Rect.fromCircle(center: origin, radius: radius));
  }

  @override
  bool shouldReclip(_RippleClipper oldClipper) =>
      oldClipper.fraction != fraction;
}

class _RippleEdgePainter extends CustomPainter {
  const _RippleEdgePainter(this.fraction);

  final double fraction;

  /// Trailing rings behind the leading edge and their spacing (logical px).
  static const int _rings = 2;
  static const double _ringGap = 20;

  @override
  void paint(Canvas canvas, Size size) {
    if (fraction <= 0 || fraction >= 1) return;
    final origin = _dropletOrigin.alongSize(size);
    final edge = _coverRadius(origin, size) * fraction;
    // Rings are strongest early and fade out as the ripple fills the screen.
    final fade = 1 - fraction;
    for (var i = 0; i < _rings; i++) {
      final radius = edge - i * _ringGap;
      if (radius <= 0) continue;
      canvas.drawCircle(
        origin,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0 - i
          ..color = AppColors.wheelConnect
              .withValues(alpha: fade * (0.45 - i * 0.15)),
      );
    }
  }

  @override
  bool shouldRepaint(_RippleEdgePainter oldDelegate) =>
      oldDelegate.fraction != fraction;
}
