// lib/shared/widgets/lily_pad.dart
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:path_drawing/path_drawing.dart';

import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/gradients.dart';
import '../../core/design/tokens/shadows.dart';

/// The recolorable surface of a lily pad. One painter serves every pad; the
/// palette swaps the fill sheen, stroke, and vein colors.
@immutable
class LilyPadPalette {
  const LilyPadPalette({
    required this.fillGradient,
    required this.strokeColor,
    required this.veinColor,
    required this.veinOpacity,
  });

  final Gradient fillGradient;
  final Color strokeColor;
  final Color veinColor;
  final double veinOpacity;

  static const green = LilyPadPalette(
    fillGradient: AppGradients.lilyGreen,
    strokeColor: AppColors.lilyGreenStroke,
    veinColor: AppColors.lilyGreenVein,
    veinOpacity: 0.55,
  );

  static const teal = LilyPadPalette(
    fillGradient: AppGradients.lilyTeal,
    strokeColor: AppColors.lilyTealStroke,
    veinColor: AppColors.lilyTealStroke,
    veinOpacity: 0.40,
  );
}

/// A lily pad: notched-circle silhouette with a radial sheen, stroke, and
/// radial vein lines, rotated, with optional centered [child] content.
class LilyPad extends StatelessWidget {
  const LilyPad({
    super.key,
    required this.size,
    required this.palette,
    this.rotationDegrees = 0,
    this.child,
  });

  final double size;
  final LilyPadPalette palette;
  final double rotationDegrees;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LilyPadPainter(
          palette: palette,
          rotationDegrees: rotationDegrees,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _LilyPadPainter extends CustomPainter {
  _LilyPadPainter({required this.palette, required this.rotationDegrees});

  final LilyPadPalette palette;
  final double rotationDegrees;

  // Reference geometry authored in a 100x100 viewBox.
  static const double _viewBox = 100;
  static final Path _pad = parseSvgPathData(
    'M 50 50 L 94.3 57.8 A 45 45 0 0 1 7.7 65.4 L 16.2 59.1 L 5.7 57.8 '
    'A 45 45 0 0 1 21.1 15.5 L 29.9 21.3 L 27.5 11.0 A 45 45 0 0 1 78.9 15.5 Z',
  );
  static final Path _veins = parseSvgPathData(
    'M 50 50 L 78.9 84.5 M 50 50 L 42.2 94.3 M 50 50 L 16.2 59.1 '
    'M 50 50 L 7.7 34.6 M 50 50 L 29.9 21.3 M 50 50 L 53.9 5.2',
  );

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _viewBox;
    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2)
      ..rotate(rotationDegrees * math.pi / 180)
      ..translate(-size.width / 2, -size.height / 2)
      ..scale(scale);

    const rect = Rect.fromLTWH(0, 0, _viewBox, _viewBox);

    // Soft cast shadow under the pad.
    final shadow = AppShadows.pad.first;
    final shadowPaint = Paint()
      ..color = shadow.color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurRadius / scale);
    canvas
      ..save()
      ..translate(0, shadow.offset.dy / scale)
      ..drawPath(_pad, shadowPaint)
      ..restore();

    // Fill sheen.
    canvas.drawPath(
      _pad,
      Paint()..shader = palette.fillGradient.createShader(rect),
    );

    // Edge stroke.
    canvas.drawPath(
      _pad,
      Paint()
        ..color = palette.strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round,
    );

    // Radial veins.
    canvas.drawPath(
      _veins,
      Paint()
        ..color = palette.veinColor.withValues(alpha: palette.veinOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_LilyPadPainter old) =>
      old.palette != palette || old.rotationDegrees != rotationDegrees;
}
