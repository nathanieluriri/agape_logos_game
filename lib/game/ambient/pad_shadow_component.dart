import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';

import '../../core/design/pad_geometry.dart';
import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/elevation.dart';

/// A large, flat submerged lily-pad silhouette drifting slowly under the
/// surface. Uses the shared notched-pad outline so the background pads read
/// as the same species as the buttons, just deeper in the water.
class PadShadowComponent extends PositionComponent {
  PadShadowComponent({
    required Vector2 position,
    required this.radius,
    required this.drift,
    required this.phase,
    required this.rotation,
    required this.color,
  }) : super(
          position: position,
          size: Vector2.all(radius * 2),
          anchor: Anchor.center,
        );

  final double radius;
  final double drift;
  final double rotation;
  final Color color;
  double phase;

  late final Paint _paint = Paint()
    ..color = color
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

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
    // Gentle depth breath: the pad swells and fades a touch, out of phase with
    // its drift, so the field reads as water depth rather than a flat decal.
    // Driven by the same [phase] that drives the drift in update().
    // PLAN: `color.a` is the wide-gamut accessor used elsewhere; if the SDK
    // rejects it, use `(color.value >> 24 & 0xFF) / 255.0`. Mutating
    // _paint.color each frame is intended (Paint is mutable). Eyeball on
    // device: the breath must be barely perceptible.
    final wobble = sin(phase * PadElevation.ambientBreatheFreq); // -1..1
    final scale = (radius * 2) /
        PadGeometry.viewBox *
        (1 + PadElevation.ambientScaleGain * wobble);
    final breath = (wobble + 1) / 2; // 0 at deepest, 1 at shallowest.
    _paint.color = color.withValues(
      alpha: color.a * (1 - PadElevation.ambientOpacityGain * breath),
    );
    canvas
      ..save()
      ..translate(radius, radius)
      ..rotate(rotation)
      ..scale(scale)
      ..translate(-PadGeometry.center.dx, -PadGeometry.center.dy)
      ..drawPath(PadGeometry.notchedPad, _paint)
      ..restore();
  }

  static List<PadShadowComponent> field(Vector2 size, Random rng) {
    return List.generate(5, (i) {
      final r = 90.0 + rng.nextDouble() * 130; // 90..220
      return PadShadowComponent(
        position: Vector2(rng.nextDouble() * size.x, rng.nextDouble() * size.y),
        radius: r,
        drift: 8 + rng.nextDouble() * 6,
        phase: rng.nextDouble() * pi * 2,
        rotation: rng.nextDouble() * pi * 2,
        color: i.isEven
            ? AppColors.ambientPadFill
            : AppColors.ambientPadFillSoft,
      );
    });
  }
}
