import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';

import '../../core/design/tokens/colors.dart';

/// A faint surface ripple drifting horizontally.
///
/// The blurred oval is rasterized once and blitted every frame: a
/// `MaskFilter.blur` at draw time would re-blur the shape on every frame.
class RippleComponent extends PositionComponent {
  RippleComponent({
    required Vector2 position,
    required this.rippleWidth,
    required this.phase,
  }) : super(position: position, anchor: Anchor.center);

  final double rippleWidth;
  double phase;

  static const double _blurSigma = 2;
  static const double _height = 4;

  /// The blur bleeds past the oval, so the raster is padded on every side.
  static const double _bleed = 8;

  late final double _density =
      ui.PlatformDispatcher.instance.implicitView?.devicePixelRatio ?? 1;

  late final double _dstWidth = rippleWidth + _bleed * 2;
  late final double _dstHeight = _height + _bleed * 2;
  late final int _rasterWidth = (_dstWidth * _density).ceil();
  late final int _rasterHeight = (_dstHeight * _density).ceil();

  late final Rect _src =
      Rect.fromLTWH(0, 0, _rasterWidth.toDouble(), _rasterHeight.toDouble());
  late final Rect _dst = Rect.fromCenter(
    center: Offset.zero,
    width: _dstWidth,
    height: _dstHeight,
  );

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
      ..scale(_density)
      ..drawOval(
        Rect.fromCenter(
          center: Offset(_dstWidth / 2, _dstHeight / 2),
          width: rippleWidth,
          height: _height,
        ),
        Paint()
          ..color = AppColors.ripple
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _blurSigma),
      );
    final picture = recorder.endRecording();
    final image = picture.toImageSync(_rasterWidth, _rasterHeight);
    picture.dispose();
    return image;
  }

  @override
  void update(double dt) {
    _origin ??= position.clone();
    phase += dt * 0.6;
    position.x = _origin!.x + 14 * sin(phase);
  }

  @override
  void render(Canvas canvas) {
    final raster = _raster;
    if (raster == null) return;
    canvas.drawImageRect(raster, _src, _dst, _paint);
  }

  static List<RippleComponent> field(Vector2 size, Random rng) {
    return List.generate(4, (i) {
      return RippleComponent(
        position: Vector2(
          rng.nextDouble() * size.x,
          size.y * (0.34 + i * 0.16),
        ),
        rippleWidth: 90 + rng.nextDouble() * 100,
        phase: rng.nextDouble() * pi * 2,
      );
    });
  }
}
