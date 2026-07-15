import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/durations.dart';

/// A one-shot confetti burst that pops every time the combo climbs (combo >= 2).
///
/// Deliberately dependency-free: token-colored paper bits are launched radially
/// from the centre, carried a little sideways by wind, pulled down by gravity,
/// spun, and shrunk-and-faded out over [AppDurations.confetti]. Purely
/// decorative, so it ignores pointers and never affects layout (it paints
/// outside its box). Honors the platform reduced-motion setting by not firing.
class StreakConfetti extends StatefulWidget {
  const StreakConfetti({super.key, required this.combo});

  final int combo;

  @override
  State<StreakConfetti> createState() => _StreakConfettiState();
}

class _StreakConfettiState extends State<StreakConfetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.confetti,
  );
  final math.Random _rng = math.Random();
  List<_Confetto> _particles = const <_Confetto>[];

  // PLAN: _count, _gravity, _endShrink, and the per-particle wind/speed ranges
  // are the feel knobs. Confetti is not in the golden set, so only the device
  // pass matters here.
  static const int _count = 24;

  /// Festive spray pulled from the existing palette (gold, lime, mints, the
  /// combo capsule's purple/pink), so it stays on-brand.
  static const List<Color> _palette = <Color>[
    AppColors.accent,
    AppColors.progressFillStart,
    AppColors.progressFillEnd,
    AppColors.lilyGreenLight,
    AppColors.plusButtonLight,
    AppColors.comboBannerStart,
    AppColors.comboBannerEnd,
  ];

  @override
  void didUpdateWidget(StreakConfetti oldWidget) {
    super.didUpdateWidget(oldWidget);
    final climbed = widget.combo != oldWidget.combo && widget.combo >= 2;
    if (!climbed) return;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) return;
    _particles = _spawn();
    _controller.forward(from: 0);
  }

  List<_Confetto> _spawn() {
    return List<_Confetto>.generate(_count, (_) {
      return _Confetto(
        // Full radial burst; gravity then arcs everything back down.
        angle: _rng.nextDouble() * 2 * math.pi,
        speed: 70 + _rng.nextDouble() * 120,
        color: _palette[_rng.nextInt(_palette.length)],
        size: 5 + _rng.nextDouble() * 5,
        aspect: 0.4 + _rng.nextDouble() * 0.9,
        spin: (_rng.nextDouble() * 2 - 1) * 7,
        // A little sideways drift so the spray is not perfectly symmetric.
        wind: (_rng.nextDouble() * 2 - 1) * 44,
        // Roughly one bit in three is a round sparkle instead of a streamer.
        round: _rng.nextInt(3) == 0,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(
              particles: _particles,
              t: _controller.value,
            ),
          ),
        ),
      ),
    );
  }
}

/// One paper bit: launch [angle]/[speed], drift [wind], draw [color]/[size]/
/// [aspect] as a streamer or a [round] sparkle, and [spin] over the flight.
class _Confetto {
  const _Confetto({
    required this.angle,
    required this.speed,
    required this.color,
    required this.size,
    required this.aspect,
    required this.spin,
    required this.wind,
    required this.round,
  });

  final double angle;
  final double speed;
  final Color color;
  final double size;
  final double aspect;
  final double spin;
  final double wind;
  final bool round;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.particles, required this.t});

  final List<_Confetto> particles;
  final double t;

  /// Downward pull applied over the flight (logical px at t = 1).
  static const double _gravity = 480;

  /// Fraction of the flight spent fully opaque before the fade-out begins.
  static const double _holdFraction = 0.6;

  /// How much each bit shrinks by the end of its flight.
  static const double _endShrink = 0.35;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1 || particles.isEmpty) return;
    final origin = size.center(Offset.zero);
    // Distance eases out (fast launch, gentle settle); fall is quadratic.
    final ease = Curves.easeOut.transform(t);
    final fade = t < _holdFraction
        ? 1.0
        : (1 - (t - _holdFraction) / (1 - _holdFraction));
    final shrink = 1 - _endShrink * t;

    for (final p in particles) {
      final distance = p.speed * ease;
      final pos =
          origin +
          Offset(
            math.cos(p.angle) * distance + p.wind * t,
            math.sin(p.angle) * distance + _gravity * t * t,
          );
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.spin * t);
      final paint = Paint()
        ..color = p.color.withValues(alpha: fade.clamp(0.0, 1.0));
      final w = p.size * shrink;
      if (p.round) {
        canvas.drawCircle(Offset.zero, w / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: w,
              height: w * p.aspect,
            ),
            const Radius.circular(1),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.t != t || !identical(oldDelegate.particles, particles);
}
