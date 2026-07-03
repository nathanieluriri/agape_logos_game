// lib/shared/widgets/brand_mark.dart
import 'package:flutter/widgets.dart';

import '../../core/design/brand_mark_geometry.dart';
import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/gradients.dart';

/// The app's brand mark: a 2x2 grid of ivory-framed pink lotus tiles with a
/// crimson lotus-bud keystone in the top-left corner.
///
/// Pass [piece] to render just one of the five pieces (0..3 tiles, 4 bud) at
/// its home position; five single-piece marks stacked at the same [size]
/// reassemble the whole logo. This is what lets the splash animate each block
/// independently while a plain `BrandMark(size: ...)` draws the finished mark.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, required this.size, this.piece});

  final double size;

  /// null draws the whole mark; 0..3 a single tile; 4 the crimson bud.
  final int? piece;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _BrandMarkPainter(piece)),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  const _BrandMarkPainter(this.piece);

  final int? piece;

  bool _draws(int index) => piece == null || piece == index;

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.width / BrandMarkGeometry.viewBox;
    canvas
      ..save()
      ..scale(scale);

    for (var i = 0; i < 4; i++) {
      if (_draws(i)) _paintTile(canvas, i);
    }
    if (_draws(4)) _paintBud(canvas);

    canvas.restore();
  }

  void _paintTile(Canvas canvas, int index) {
    final Rect outer = BrandMarkGeometry.tileRect(index);
    final Rect inner = outer.deflate(BrandMarkGeometry.frame);
    final RRect outerRR = RRect.fromRectAndRadius(
        outer, const Radius.circular(BrandMarkGeometry.tileRadius));
    final RRect innerRR = RRect.fromRectAndRadius(
        inner, const Radius.circular(BrandMarkGeometry.innerRadius));

    // Ivory frame, a darker pink underside for pressed depth, then the sheen.
    canvas
      ..drawRRect(outerRR, Paint()..color = AppColors.markCream)
      ..drawRRect(
          innerRR.shift(const Offset(0, 1.4)),
          Paint()..color = AppColors.markPinkEdge)
      ..drawRRect(
          innerRR, Paint()..shader = AppGradients.markPane.createShader(inner))
      ..drawPath(
        BrandMarkGeometry.petalRosette(inner),
        Paint()..color = AppColors.markPetal.withValues(alpha: 0.5),
      );
  }

  void _paintBud(Canvas canvas) {
    final Rect outer = BrandMarkGeometry.budRect;
    final Rect inner = outer.deflate(BrandMarkGeometry.frame);
    final RRect outerRR = RRect.fromRectAndRadius(
        outer, const Radius.circular(BrandMarkGeometry.budRadius));
    final RRect innerRR =
        RRect.fromRectAndRadius(inner, const Radius.circular(6));

    canvas
      ..drawRRect(outerRR, Paint()..color = AppColors.markCream)
      ..drawRRect(
          innerRR.shift(const Offset(0, 1.2)),
          Paint()..color = AppColors.markCrimsonDeep)
      ..drawRRect(
          innerRR, Paint()..shader = AppGradients.markBud.createShader(inner))
      ..drawPath(
        BrandMarkGeometry.lotusBud(inner.deflate(inner.width * 0.14)),
        Paint()..color = AppColors.markCrimsonPetal,
      );
  }

  @override
  bool shouldRepaint(_BrandMarkPainter old) => old.piece != piece;
}
