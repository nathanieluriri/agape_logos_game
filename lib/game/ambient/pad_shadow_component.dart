import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';

import '../../core/design/tokens/colors.dart';

/// A soft, slowly drifting submerged lily-pad shadow blob.
class PadShadowComponent extends PositionComponent {
  PadShadowComponent({
    required Vector2 position,
    required this.radius,
    required this.drift,
    required this.phase,
  }) : super(position: position, size: Vector2.all(radius * 2), anchor: Anchor.center);

  final double radius;
  final double drift;
  double phase;

  late final Paint _paint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7)
    ..shader = const RadialGradient(
      colors: [
        AppColors.padShadowCore,
        AppColors.padShadowMid,
        AppColors.padShadowEdge,
      ],
      stops: [0.0, 0.55, 0.78],
    ).createShader(Rect.fromCircle(center: Offset(radius, radius), radius: radius));

  Vector2? _origin;

  @override
  void update(double dt) {
    _origin ??= position.clone();
    phase += dt * 0.3;
    position
      ..x = _origin!.x - drift * (1 + sin(phase)) / 2
      ..y = _origin!.y - drift * (1 + sin(phase * 0.8)) / 2;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset(radius, radius), radius, _paint);
  }

  static List<PadShadowComponent> field(Vector2 size, Random rng) {
    return List.generate(6, (i) {
      final r = 45.0 + rng.nextDouble() * 135; // 45..180
      return PadShadowComponent(
        position: Vector2(rng.nextDouble() * size.x, rng.nextDouble() * size.y),
        radius: r,
        drift: 8 + rng.nextDouble() * 6,
        phase: rng.nextDouble() * pi * 2,
      );
    });
  }
}
