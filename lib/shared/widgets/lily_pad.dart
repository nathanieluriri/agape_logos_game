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
///
/// The pad is split into two paint layers on purpose: the cast shadow (the only
/// thing that responds to [lift], and the only expensive op, a blurred mask) and
/// the pad body (fill, veins, rim), which never changes while the pad bobs. The
/// body sits behind its own [RepaintBoundary] so a per-frame [lift] change
/// re-rasterizes the shadow layer alone, not the gradients and vein texture.
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
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (shadow)
            CustomPaint(
              painter: _PadShadowPainter(
                shape: shape,
                rotationDegrees: rotationDegrees,
                lift: lift,
              ),
            ),
          RepaintBoundary(
            child: CustomPaint(
              painter: _PadBodyPainter(
                palette: palette,
                shape: shape,
                rotationDegrees: rotationDegrees,
              ),
              child: Center(child: child),
            ),
          ),
        ],
      ),
    );
  }
}

/// The silhouette (and its veins) rotated in place, memoized per
/// (shape, rotation). The canvas itself stays unrotated so gradients, shadow
/// offsets, and the rim glow remain in screen space.
///
/// Follows the `static final` path pattern of [PadGeometry]: pads are rebuilt
/// every animation tick, so nothing here may allocate a Matrix4 or transform a
/// Path per frame.
@immutable
class _PadPaths {
  const _PadPaths(this.outline, this.veins);
  final Path outline;
  final Path veins;
}

final Map<(PadShape, double), _PadPaths> _pathCache = {};

_PadPaths _pathsFor(PadShape shape, double rotationDegrees) {
  return _pathCache.putIfAbsent((shape, rotationDegrees), () {
    final base = shape == PadShape.smooth
        ? PadGeometry.smoothPad
        : PadGeometry.notchedPad;
    if (rotationDegrees == 0) return _PadPaths(base, PadGeometry.veins);
    final Float64List rotation = (Matrix4.identity()
          ..translateByDouble(PadGeometry.center.dx, PadGeometry.center.dy, 0, 1)
          ..rotateZ(rotationDegrees * math.pi / 180)
          ..translateByDouble(
              -PadGeometry.center.dx, -PadGeometry.center.dy, 0, 1))
        .storage;
    return _PadPaths(
      base.transform(rotation),
      PadGeometry.veins.transform(rotation),
    );
  });
}

/// The painter's canvas is scaled to the viewBox, so every gradient is shaded
/// against this rect whatever the pad's pixel size: the shaders can be built
/// once per palette rather than once per paint.
const Rect _viewBoxRect =
    Rect.fromLTWH(0, 0, PadGeometry.viewBox, PadGeometry.viewBox);

const double _veinStrokeWidth = 1.3;
const double _rimStrokeWidth = 1.8;

/// How far the darker underside peeks out below the fill (viewBox units).
const double _undersideDrop = 3.2;

/// Every Paint (and both shaders) a body layer needs, built once per palette.
class _PadBodyPaints {
  _PadBodyPaints(LilyPadPalette palette)
      : underside = (Paint()..color = palette.underside),
        fill = (Paint()
          ..shader = palette.fillGradient.createShader(_viewBoxRect)),
        veins = (palette.veinColor == null || palette.veinOpacity <= 0)
            ? null
            : (Paint()
              ..color =
                  palette.veinColor!.withValues(alpha: palette.veinOpacity)
              ..style = PaintingStyle.stroke
              ..strokeWidth = _veinStrokeWidth
              ..strokeCap = StrokeCap.round),
        rim = (Paint()
          ..shader = AppGradients.padRimGlow.createShader(_viewBoxRect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = _rimStrokeWidth);

  final Paint underside;
  final Paint fill;
  final Paint? veins;
  final Paint rim;
}

final Map<LilyPadPalette, _PadBodyPaints> _bodyPaintCache = {};

_PadBodyPaints _bodyPaintsFor(LilyPadPalette palette) =>
    _bodyPaintCache.putIfAbsent(palette, () => _PadBodyPaints(palette));

/// The pad body: darker underside, fill sheen, vein texture, rim glow. Nothing
/// here responds to the bob, so this never repaints while a pad floats.
class _PadBodyPainter extends CustomPainter {
  const _PadBodyPainter({
    required this.palette,
    required this.shape,
    required this.rotationDegrees,
  });

  final LilyPadPalette palette;
  final PadShape shape;
  final double rotationDegrees;

  @override
  void paint(Canvas canvas, Size size) {
    final paths = _pathsFor(shape, rotationDegrees);
    final paints = _bodyPaintsFor(palette);

    canvas
      ..save()
      ..scale(size.width / PadGeometry.viewBox);

    // 1. Hard darker underside peeking out below the fill.
    canvas
      ..save()
      ..translate(0, _undersideDrop)
      ..drawPath(paths.outline, paints.underside)
      ..restore();

    // 2. Fill sheen (top-left light source).
    canvas.drawPath(paths.outline, paints.fill);

    // 3. Subtle radial vein texture.
    final veins = paints.veins;
    if (veins != null) canvas.drawPath(paths.veins, veins);

    // 4. Light rim glow, brightest along the top edge.
    canvas
      ..drawPath(paths.outline, paints.rim)
      ..restore();
  }

  @override
  bool shouldRepaint(_PadBodyPainter old) =>
      old.palette != palette ||
      old.shape != shape ||
      old.rotationDegrees != rotationDegrees;
}

/// The soft cast shadow on the water. As the pad lifts (0..1) the shadow grows
/// and softens (blur), drops further from the pad (offset), and fades
/// (opacity), which reads as the pad floating higher above the surface. At
/// lift 0 this is byte-identical to the resting recipe.
class _PadShadowPainter extends CustomPainter {
  const _PadShadowPainter({
    required this.shape,
    required this.rotationDegrees,
    required this.lift,
  });

  final PadShape shape;
  final double rotationDegrees;
  final double lift;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / PadGeometry.viewBox;
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
      ..scale(scale)
      ..translate(0, dropY / scale)
      ..drawPath(_pathsFor(shape, rotationDegrees).outline, shadowPaint)
      ..restore();
  }

  @override
  bool shouldRepaint(_PadShadowPainter old) =>
      old.lift != lift ||
      old.shape != shape ||
      old.rotationDegrees != rotationDegrees;
}
