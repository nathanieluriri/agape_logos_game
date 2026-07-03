// lib/shared/widgets/lily_pad.dart
import 'dart:math' as math;
import 'dart:typed_data' show Float64List;

import 'package:flutter/widgets.dart';

import '../../core/design/pad_geometry.dart';
import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/gradients.dart';
import '../../core/design/tokens/shadows.dart';

/// The recolorable surface of a pad. One painter serves every pad; the
/// palette swaps the fill sheen, the darker underside, and the vein texture.
@immutable
class LilyPadPalette {
  const LilyPadPalette({
    required this.fillGradient,
    required this.underside,
    this.veinColor,
    this.veinOpacity = 0,
  });

  final Gradient fillGradient;

  /// The darker copy peeking out under the bottom edge (pressed-clay depth).
  final Color underside;

  /// Optional radial vein texture; null paints no veins.
  final Color? veinColor;
  final double veinOpacity;

  static const green = LilyPadPalette(
    fillGradient: AppGradients.lilyGreen,
    underside: AppColors.lilyGreenUnder,
    veinColor: AppColors.lilyGreenVein,
    veinOpacity: 0.30,
  );

  static const teal = LilyPadPalette(
    fillGradient: AppGradients.lilyTeal,
    underside: AppColors.lilyTealUnder,
  );

  static const bonusBlue = LilyPadPalette(
    fillGradient: AppGradients.bonusBlue,
    underside: AppColors.bonusBlueUnder,
  );
}

/// The silhouette a pad is drawn with. Both are the softly rounded
/// three-sided base; [notched] adds the two rim nicks of the play pad.
enum PadShape { notched, smooth }

/// A pad resting on the water: a soft cast shadow, a darker underside, a
/// radial-sheen fill, subtle vein texture, and a light rim glow along the
/// top edge, with optional centered [child] content.
class LilyPad extends StatelessWidget {
  const LilyPad({
    super.key,
    required this.size,
    required this.palette,
    this.shape = PadShape.notched,
    this.rotationDegrees = 0,
    this.shadow = true,
    this.child,
  });

  final double size;
  final LilyPadPalette palette;
  final PadShape shape;
  final double rotationDegrees;

  /// Whether to paint the soft cast shadow under the pad. On by default: the
  /// reference pads all sit on a pool of shadowed water.
  final bool shadow;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LilyPadPainter(
          palette: palette,
          shape: shape,
          rotationDegrees: rotationDegrees,
          shadow: shadow,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _LilyPadPainter extends CustomPainter {
  _LilyPadPainter({
    required this.palette,
    required this.shape,
    required this.rotationDegrees,
    required this.shadow,
  });

  final LilyPadPalette palette;
  final PadShape shape;
  final double rotationDegrees;
  final bool shadow;

  /// How far the darker underside peeks out below the fill (viewBox units).
  static const double _undersideDrop = 3.2;

  /// The silhouette rotated in place; the canvas itself stays unrotated so
  /// gradients, shadow offsets, and the rim glow remain in screen space.
  late final Float64List _rotation = (Matrix4.identity()
        ..translateByDouble(PadGeometry.center.dx, PadGeometry.center.dy, 0, 1)
        ..rotateZ(rotationDegrees * math.pi / 180)
        ..translateByDouble(
            -PadGeometry.center.dx, -PadGeometry.center.dy, 0, 1))
      .storage;

  late final Path _outline =
      (shape == PadShape.smooth ? PadGeometry.smoothPad : PadGeometry.notchedPad)
          .transform(_rotation);

  late final Path _veins = PadGeometry.veins.transform(_rotation);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / PadGeometry.viewBox;
    canvas
      ..save()
      ..scale(scale);

    const rect = Rect.fromLTWH(0, 0, PadGeometry.viewBox, PadGeometry.viewBox);

    // 1. Soft cast shadow on the water.
    if (shadow) {
      final cast = AppShadows.pad.first;
      final shadowPaint = Paint()
        ..color = cast.color
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          Shadow.convertRadiusToSigma(cast.blurRadius) / scale,
        );
      canvas
        ..save()
        ..translate(0, cast.offset.dy / scale)
        ..drawPath(_outline, shadowPaint)
        ..restore();
    }

    // 2. Hard darker underside peeking out below the fill.
    canvas
      ..save()
      ..translate(0, _undersideDrop)
      ..drawPath(_outline, Paint()..color = palette.underside)
      ..restore();

    // 3. Fill sheen (top-left light source).
    canvas.drawPath(
      _outline,
      Paint()..shader = palette.fillGradient.createShader(rect),
    );

    // 4. Subtle radial vein texture.
    final veinColor = palette.veinColor;
    if (veinColor != null && palette.veinOpacity > 0) {
      canvas.drawPath(
        _veins,
        Paint()
          ..color = veinColor.withValues(alpha: palette.veinOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3
          ..strokeCap = StrokeCap.round,
      );
    }

    // 5. Light rim glow, brightest along the top edge.
    canvas.drawPath(
      _outline,
      Paint()
        ..shader = AppGradients.padRimGlow.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_LilyPadPainter old) =>
      old.palette != palette ||
      old.shape != shape ||
      old.rotationDegrees != rotationDegrees ||
      old.shadow != shadow;
}
