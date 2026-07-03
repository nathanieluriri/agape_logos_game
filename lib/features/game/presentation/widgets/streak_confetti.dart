import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/durations.dart';

/// A one-shot confetti burst that pops every time the combo climbs (combo >= 2).
///
/// Deliberately dependency-free: a handful of token-colored paper bits are
/// launched radially from the centre, pulled down by a little gravity, spun,
/// and faded out over [AppDurations.confetti]. Purely decorative, so it ignores
/// pointers and never affects layout (it paints outside its box). Honors the
/// platform reduced-motion setting by simply not firing.
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

  static const int _count = 16;

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
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) return;
    _particles = _spawn();
    _controller.forward(from: 0);
  }

  List<_Confetto> _spawn() {
    return List<_Confetto>.generate(_count, (_) {
      return _Confetto(
        // Full radial burst; gravity then arcs everything back down.
        angle: _rng.nextDouble() * 2 * math.pi,
        speed: 64 + _rng.nextDouble() * 104,
        color: _palette[_rng.nextInt(_palette.length)],
        size: 5 + _rng.nextDouble() * 4,
        aspect: 0.4 + _rng.nextDouble() * 0.9,
        spin: (_rng.nextDouble() * 2 - 1) * 6,
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

/// One paper bit: launch [angle]/[speed], draw [color]/[size]/[aspect], and
/// [spin] over the flight.
class _Confetto {
  const _Confetto({
    required this.angle,
    required this.speed,
    required this.color,
    required this.size,
    required this.aspect,
    required this.spin,
  });

  final double angle;
  final double speed;
  final Color color;
  final double size;
  final double aspect;
  final double spin;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.particles, required this.t});

  final List<_Confetto> particles;
  final double t;

  /// Downward pull applied over the flight (logical px at t = 1).
  static const double _gravity = 460;

  /// Fraction of the flight spent fully opaque before the fade-out begins.
  static const double _holdFraction = 0.65;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1 || particles.isEmpty) return;
    final origin = size.center(Offset.zero);
    // Distance eases out (fast launch, gentle settle); fall is quadratic.
    final ease = Curves.easeOut.transform(t);
    final fade = t < _holdFraction
        ? 1.0
        : (1 - (t - _holdFraction) / (1 - _holdFraction));

    for (final p in particles) {
      final distance = p.speed * ease;
      final pos = origin +
          Offset(
            math.cos(p.angle) * distance,
            math.sin(p.angle) * distance + _gravity * t * t,
          );
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.spin * t);
      final paint = Paint()
        ..color = p.color.withValues(alpha: fade.clamp(0.0, 1.0));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * p.aspect,
          ),
          const Radius.circular(1),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.t != t || !identical(oldDelegate.particles, particles);
}
