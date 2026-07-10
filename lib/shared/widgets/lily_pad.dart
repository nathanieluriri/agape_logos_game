// lib/shared/widgets/lily_pad.dart
import 'dart:math' as math;
import 'dart:typed_data' show Float64List;

import 'package:flutter/widgets.dart';

import '../../core/design/pad_geometry.dart';
import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/elevation.dart';
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

  static const coral = LilyPadPalette(
    fillGradient: AppGradients.lilyCoral,
    underside: AppColors.lilyCoralUnder,
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
    this.lift = 0,
    this.child,
  });

  final double size;
  final LilyPadPalette palette;
  final PadShape shape;
  final double rotationDegrees;

  /// Whether to paint the soft cast shadow under the pad. On by default: the
  /// reference pads all sit on a pool of shadowed water.
  final bool shadow;

  /// How high the pad is floating, 0 (resting on the water) to 1 (top of its
  /// bob). Drives the cast shadow only: as the pad rises the shadow grows,
  /// softens, drops further, and fades. Wire this to [FloatMotion]'s builder.
  /// At 0 the shadow is identical to a static resting pad.
  final double lift;
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
          lift: lift,
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
    required this.lift,
  });

  final LilyPadPalette palette;
  final PadShape shape;
  final double rotationDegrees;
  final bool shadow;
  final double lift;

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

    // 1. Soft cast shadow on the water. As the pad lifts (0..1) the shadow
    //    grows and softens (blur), drops further from the pad (offset), and
    //    fades (opacity), which reads as the pad floating higher above the
    //    surface. At lift 0 this is byte-identical to the resting recipe.
    // PLAN: `cast.color.a` uses the Flutter 3.27+ component accessor (0..1
    // double), same wide-gamut Color API this file already uses via
    // withValues. If the SDK rejects `.a`, read the base alpha via
    // `(cast.color.value >> 24 & 0xFF) / 255.0` and keep the same fade math.
    if (shadow) {
      final cast = AppShadows.pad.first;
      final t = lift.clamp(0.0, 1.0);
      final blur = cast.blurRadius * (1 + t * PadElevation.shadowBlurGain);
      final dropY = cast.offset.dy + t * PadElevation.shadowDrop;
      final shadowPaint = Paint()
        ..color = cast.color.withValues(
          alpha: cast.color.a * (1 - t * PadElevation.shadowFade),
        )
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          Shadow.convertRadiusToSigma(blur) / scale,
        );
      canvas
        ..save()
        ..translate(0, dropY / scale)
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
      old.shadow != shadow ||
      old.lift != lift;
}
