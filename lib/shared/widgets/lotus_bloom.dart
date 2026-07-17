// lib/shared/widgets/lotus_bloom.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/durations.dart';
import '../../core/design/tokens/sizing.dart';

/// A one-shot blooming-lotus flash: a warm lime-gold core expands and fades, a
/// thin ring rings out, and a few pond-petal specks fly outward and settle. Play
/// it at a moment of arrival (a determinate loader hitting 1.0, a level fully
/// cleared). Purely decorative: it ignores pointers, paints outside its box, and
/// never affects layout. Honours reduced motion by rendering one inert frame.
class LotusBloom extends StatefulWidget {
  const LotusBloom({
    super.key,
    this.size = AppSizing.loaderBloom,
    this.onEnd,
  });

  /// Diameter of the bloom core at full expansion.
  final double size;

  /// Called once the bloom finishes (or immediately under reduced motion), so a
  /// parent can drop the overlay from its tree.
  final VoidCallback? onEnd;

  @override
  State<LotusBloom> createState() => _LotusBloomState();
}

class _LotusBloomState extends State<LotusBloom>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: AppDurations.bloomPop);
  final math.Random _rng = math.Random();
  late final List<_Speck> _specks = _spawn();

  static const int _speckCount = 8;

  /// Pond-petal spray: bright lime, the bloom core, and soft mint.
  static const List<Color> _palette = <Color>[
    AppColors.progressFillEnd,
    AppColors.loaderBloomCore,
    AppColors.lilyGreenLight,
    AppColors.plusButtonLight,
  ];

  @override
  void initState() {
    super.initState();
    // PLAN: reduced motion is read via
    // platformDispatcher.accessibilityFeatures.disableAnimations in initState
    // (no context MediaQuery access before first build for a one-shot);
    // equivalent to the MediaQuery value the other widgets use.
    final reduceMotion =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures
            .disableAnimations;
    if (reduceMotion) {
      // Inert: report completion next frame, paint nothing perpetual.
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onEnd?.call());
      return;
    }
    _controller
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onEnd?.call();
      })
      ..forward();
  }

  List<_Speck> _spawn() => List<_Speck>.generate(_speckCount, (i) {
        final angle = (i / _speckCount) * 2 * math.pi +
            (_rng.nextDouble() - 0.5) * 0.6;
        return _Speck(
          angle: angle,
          distance: widget.size * (0.5 + _rng.nextDouble() * 0.4),
          radius: 2.0 + _rng.nextDouble() * 2.0,
          color: _palette[_rng.nextInt(_palette.length)],
        );
      });

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _BloomPainter(
                t: _controller.value,
                specks: _specks,
                coreColor: AppColors.loaderBloomCore,
                ringColor: AppColors.progressFillCrest,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Speck {
  const _Speck({
    required this.angle,
    required this.distance,
    required this.radius,
    required this.color,
  });

  final double angle;
  final double distance;
  final double radius;
  final Color color;
}

class _BloomPainter extends CustomPainter {
  const _BloomPainter({
    required this.t,
    required this.specks,
    required this.coreColor,
    required this.ringColor,
  });

  final double t;
  final List<_Speck> specks;
  final Color coreColor;
  final Color ringColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final center = size.center(Offset.zero);
    final ease = Curves.easeOutCubic.transform(t);
    final fade = (1 - t).clamp(0.0, 1.0);

    // Core flash: a soft radial that grows and fades.
    // PLAN: _speckCount, the ring stroke, and the core alpha are first-pass.
    // On-device the bloom should read as a gentle lotus opening, not a
    // firework; tune specks/alpha in plan 06 Task 8.
    final coreRadius = size.width * 0.5 * (0.35 + ease * 0.65);
    canvas.drawCircle(
      center,
      coreRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            coreColor.withValues(alpha: 0.65 * fade),
            coreColor.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: coreRadius)),
    );

    // Ring: a thin expanding hoop.
    canvas.drawCircle(
      center,
      size.width * 0.5 * ease,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * fade
        ..color = ringColor.withValues(alpha: 0.7 * fade),
    );

    // Petal specks: launch out, ease to rest, fade.
    for (final s in specks) {
      final d = s.distance * ease;
      final pos = center + Offset(math.cos(s.angle) * d, math.sin(s.angle) * d);
      canvas.drawCircle(
        pos,
        s.radius,
        Paint()..color = s.color.withValues(alpha: fade),
      );
    }
  }

  @override
  bool shouldRepaint(_BloomPainter old) =>
      old.t != t || !identical(old.specks, specks);
}
