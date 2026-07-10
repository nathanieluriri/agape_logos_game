// lib/shared/widgets/glyphs/glyph_paths.dart
import 'dart:ui';

/// The glyph vocabulary of the pond design system. Each case maps to a
/// hand-authored path in [GlyphPaths]; rendering happens in PondGlyphPainter.
enum PondGlyph { play, book, versus, plus, key, chevronLeft, friends }

/// One glyph's geometry: a path in the 100x100 viewBox, drawn filled when
/// [strokeWidth] is null, otherwise stroked with round caps and joins.
class GlyphSpec {
  GlyphSpec.fill(this.path) : strokeWidth = null;
  GlyphSpec.stroke(this.path, this.strokeWidth);

  final Path path;
  final double? strokeWidth;
}

/// Hand-authored glyph paths, all in a 100x100 viewBox (the same convention
/// as PadGeometry). Pure geometry: no colors, no widgets.
abstract final class GlyphPaths {
  static final Map<PondGlyph, GlyphSpec> _cache = {};

  static GlyphSpec spec(PondGlyph glyph) =>
      _cache.putIfAbsent(glyph, () => switch (glyph) {
            PondGlyph.play => GlyphSpec.fill(_play()),
            PondGlyph.book => GlyphSpec.fill(_book()),
            PondGlyph.versus => GlyphSpec.stroke(_versus(), 13),
            PondGlyph.plus => GlyphSpec.stroke(_plus(), 18),
            PondGlyph.key => GlyphSpec.stroke(_key(), 12),
            PondGlyph.chevronLeft => GlyphSpec.stroke(_chevronLeft(), 16),
            PondGlyph.friends => GlyphSpec.fill(_friends()),
          });

  /// Rounded right-pointing triangle, ported from the original PlayTriangle
  /// painter (corner radius ~22% of the short side, here fixed in viewBox
  /// units).
  static Path _play() => _roundedPoly(
        const [Offset(16, 10), Offset(88, 50), Offset(16, 90)],
        16,
      );

  /// Open book: two soft page panels meeting at a centre spine.
  static Path _book() => Path()
    ..moveTo(50, 30)
    ..quadraticBezierTo(32, 20, 16, 26)
    ..lineTo(16, 72)
    ..quadraticBezierTo(34, 66, 50, 76)
    ..quadraticBezierTo(66, 66, 84, 72)
    ..lineTo(84, 26)
    ..quadraticBezierTo(68, 20, 50, 30)
    ..close();

  /// Two facing chevrons with a calm gap: opposition without violence.
  static Path _versus() => Path()
    ..moveTo(26, 26)
    ..lineTo(44, 50)
    ..lineTo(26, 74)
    ..moveTo(74, 26)
    ..lineTo(56, 50)
    ..lineTo(74, 74);

  static Path _plus() => Path()
    ..moveTo(50, 24)
    ..lineTo(50, 76)
    ..moveTo(24, 50)
    ..lineTo(76, 50);

  /// Round-bow key lying horizontally, two teeth pointing down.
  static Path _key() => Path()
    ..addOval(Rect.fromCircle(center: const Offset(32, 50), radius: 15))
    ..moveTo(47, 50)
    ..lineTo(84, 50)
    ..moveTo(66, 50)
    ..lineTo(66, 64)
    ..moveTo(82, 50)
    ..lineTo(82, 68);

  static Path _chevronLeft() => Path()
    ..moveTo(60, 20)
    ..lineTo(32, 50)
    ..lineTo(60, 80);

  /// Two overlapping round heads over shoulder bumps; the front (right)
  /// figure overlaps the back one, fills merge under non-zero winding.
  static Path _friends() => Path()
    ..addOval(Rect.fromCircle(center: const Offset(36, 36), radius: 13))
    ..addOval(Rect.fromCircle(center: const Offset(64, 40), radius: 14))
    ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTRB(18, 56, 56, 84), const Radius.circular(19)))
    ..addRRect(RRect.fromRectAndRadius(
        const Rect.fromLTRB(44, 60, 88, 90), const Radius.circular(21)));

  /// Closed polygon with every corner rounded by radius [r] (quadratic
  /// bezier through the vertex), generalized from the PlayTriangle painter.
  static Path _roundedPoly(List<Offset> pts, double r) {
    final path = Path();
    for (var i = 0; i < pts.length; i++) {
      final p = pts[i];
      final prev = pts[(i - 1 + pts.length) % pts.length];
      final next = pts[(i + 1) % pts.length];
      final inUnit = (p - prev) / (p - prev).distance;
      final outUnit = (next - p) / (next - p).distance;
      final entry = p - inUnit * r;
      final exit = p + outUnit * r;
      if (i == 0) {
        path.moveTo(entry.dx, entry.dy);
      } else {
        path.lineTo(entry.dx, entry.dy);
      }
      path.quadraticBezierTo(p.dx, p.dy, exit.dx, exit.dy);
    }
    return path..close();
  }
}
