import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';

import '../../core/design/tokens/colors.dart';

/// A faint surface ripple drifting horizontally.
class RippleComponent extends PositionComponent {
  RippleComponent({
    required Vector2 position,
    required this.rippleWidth,
    required this.phase,
  }) : super(position: position, anchor: Anchor.center);

  final double rippleWidth;
  double phase;
  Vector2? _origin;

  late final Paint _paint = Paint()
    ..color = AppColors.ripple
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

  @override
  void update(double dt) {
    _origin ??= position.clone();
    phase += dt * 0.6;
    position.x = _origin!.x + 14 * sin(phase);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: rippleWidth, height: 7),
      _paint,
    );
  }

  static List<RippleComponent> field(Vector2 size, Random rng) {
    return List.generate(3, (i) {
      return RippleComponent(
        position: Vector2(rng.nextDouble() * size.x, size.y * (0.4 + i * 0.18)),
        rippleWidth: 80 + rng.nextDouble() * 70,
        phase: rng.nextDouble() * pi * 2,
      );
    });
  }
}
