// lib/shared/widgets/glyphs/pond_glyph_painter.dart
import 'package:flutter/widgets.dart';

import '../../../core/design/tokens/colors.dart';
import 'glyph_paths.dart';

/// Paints one [PondGlyph] with the pond "pressed clay" recipe: a darker
/// cream copy of the path nudged down 5% of the viewBox (the extrusion),
/// then the cream face on top. Stroked glyphs get round caps and joins so
/// every mark reads as the same hand.
class PondGlyphPainter extends CustomPainter {
  const PondGlyphPainter(this.glyph);

  final PondGlyph glyph;

  /// Glyphs are authored in a 100x100 viewBox (PadGeometry convention).
  static const double _viewBox = 100;

  /// Vertical extrusion offset, in viewBox units.
  static const double _drop = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final spec = GlyphPaths.spec(glyph);
    canvas
      ..scale(size.width / _viewBox, size.height / _viewBox)
      ..save()
      ..translate(0, _drop)
      ..drawPath(spec.path, _paintWith(AppColors.glyphExtrusion, spec))
      ..restore()
      ..drawPath(spec.path, _paintWith(AppColors.glyphFace, spec));
  }

  static Paint _paintWith(Color color, GlyphSpec spec) {
    final paint = Paint()..color = color;
    final width = spec.strokeWidth;
    if (width != null) {
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
    }
    return paint;
  }

  @override
  bool shouldRepaint(covariant PondGlyphPainter oldDelegate) =>
      oldDelegate.glyph != glyph;
}
