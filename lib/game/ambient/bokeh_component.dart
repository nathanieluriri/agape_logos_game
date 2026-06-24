import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../../core/design/tokens/colors.dart';

/// A single soft, slowly-drifting circle. Wraps vertically so the field never
/// empties. Pure visual: deterministic-ish via the seeded [Random] it is given.
class BokehComponent extends PositionComponent {
  BokehComponent({
    required this.radius,
    required this.speed,
    required this.opacity,
    required super.position,
  });

  final double radius;
  final double speed;
  final double opacity;

  late final Paint _paint = Paint()
    ..color = AppColors.paper.withValues(alpha: opacity);

  @override
  void update(double dt) {
    position.y -= speed * dt;
    if (position.y + radius < 0) {
      position.y = (findGame()?.size.y ?? 0) + radius;
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset.zero, radius, _paint);
  }

  /// Builds a pseudo-random field of [count] bokeh sized to [size].
  static List<BokehComponent> field(Vector2 size, int count, Random rng) {
    return List<BokehComponent>.generate(count, (_) {
      final r = 18 + rng.nextDouble() * 46;
      return BokehComponent(
        radius: r,
        speed: 4 + rng.nextDouble() * 10,
        opacity: 0.04 + rng.nextDouble() * 0.05,
        position: Vector2(rng.nextDouble() * size.x, rng.nextDouble() * size.y),
      );
    });
  }
}
