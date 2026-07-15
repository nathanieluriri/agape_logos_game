import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';

import '../../core/design/pad_geometry.dart';
import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/elevation.dart';

/// A large, flat submerged lily-pad silhouette drifting slowly under the
/// surface. Uses the shared notched-pad outline so the background pads read
/// as the same species as the buttons, just deeper in the water.
///
/// The blurred silhouette is rasterized once at the pad's largest breath size
/// and then drawn as an image: a `MaskFilter.blur` on a live path would rebuild
/// the blurred mask every frame, because both the scale and the alpha change
/// every frame.
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

  static const double _blurSigma = 6;

  /// The blur bleeds past the pad outline, so the raster is padded on every
  /// side (viewBox units) to keep the soft edge inside the image.
  static const double _bleed = 24;

  static const double _rasterViewBox = PadGeometry.viewBox + _bleed * 2;

  late final double _maxScale = (radius * 2) /
      PadGeometry.viewBox *
      (1 + PadElevation.ambientScaleGain);

  late final int _rasterSide = (_rasterViewBox * _maxScale).ceil();

  late final Rect _src =
      Rect.fromLTWH(0, 0, _rasterSide.toDouble(), _rasterSide.toDouble());

  static const Rect _dst =
      Rect.fromLTWH(-_bleed, -_bleed, _rasterViewBox, _rasterViewBox);

  final Paint _paint = Paint()..filterQuality = FilterQuality.low;

  ui.Image? _raster;
  Vector2? _origin;

  @override
  void onLoad() {
    _raster = _rasterize();
  }

  @override
  void onRemove() {
    _raster?.dispose();
    _raster = null;
    super.onRemove();
  }

  ui.Image _rasterize() {
    final recorder = ui.PictureRecorder();
    Canvas(recorder)
      ..scale(_maxScale)
      ..translate(_bleed, _bleed)
      ..drawPath(
        PadGeometry.notchedPad,
        Paint()
          ..color = color
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _blurSigma),
      );
    final picture = recorder.endRecording();
    final image = picture.toImageSync(_rasterSide, _rasterSide);
    picture.dispose();
    return image;
  }

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
    final raster = _raster;
    if (raster == null) return;

    final wobble = sin(phase * PadElevation.ambientBreatheFreq); // -1..1
    final scale = (radius * 2) /
        PadGeometry.viewBox *
        (1 + PadElevation.ambientScaleGain * wobble);
    final breath = (wobble + 1) / 2; // 0 at deepest, 1 at shallowest.

    // The pad's own alpha is already baked into the raster, so only the breath
    // factor is modulated here. The RGB channels are unused by drawImageRect.
    _paint.color = color.withValues(
      alpha: 1 - PadElevation.ambientOpacityGain * breath,
    );

    canvas
      ..save()
      ..translate(radius, radius)
      ..rotate(rotation)
      ..scale(scale)
      ..translate(-PadGeometry.center.dx, -PadGeometry.center.dy)
      ..drawImageRect(raster, _src, _dst, _paint)
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
