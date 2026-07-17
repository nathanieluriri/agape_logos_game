// lib/shared/widgets/glyphs/glyph_paths.dart
import 'dart:ui';

/// The glyph vocabulary of the pond design system. Each case maps to a
/// hand-authored path in [GlyphPaths]; rendering happens in PondGlyphPainter.
enum PondGlyph { play, book, versus, plus, key, chevronLeft, friends, swords, shield }

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
            PondGlyph.versus => GlyphSpec.fill(_versus()),
            PondGlyph.plus => GlyphSpec.stroke(_plus(), 18),
            PondGlyph.key => GlyphSpec.stroke(_key(), 12),
            PondGlyph.chevronLeft => GlyphSpec.stroke(_chevronLeft(), 16),
            PondGlyph.friends => GlyphSpec.fill(_friends()),
            PondGlyph.swords => GlyphSpec.fill(_swords()),
            PondGlyph.shield => GlyphSpec.fill(_shield()),
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

  /// Two play triangles facing off across a calm channel: opposition without
  /// violence, and a deliberate echo of the Play glyph (same rounded silhouette,
  /// mirrored). Filled rather than stroked: at pad size (28px) thin strokes with
  /// round caps close the gap and read as a single X.
  static Path _versus() => Path()
    ..addPath(_roundedPoly(
      const [Offset(8, 18), Offset(38, 50), Offset(8, 82)],
      9,
    ), Offset.zero)
    ..addPath(_roundedPoly(
      const [Offset(92, 18), Offset(62, 50), Offset(92, 82)],
      9,
    ), Offset.zero);

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

  /// Two crossed blades: the offense powerup mark. Each blade is a thin
  /// rounded quad along its diagonal.
  static Path _swords() => Path()
    ..addPath(_blade(const Offset(18, 18), const Offset(82, 82)), Offset.zero)
    ..addPath(_blade(const Offset(82, 18), const Offset(18, 82)), Offset.zero);

  static Path _blade(Offset a, Offset b) {
    final dir = b - a;
    final unit = dir / dir.distance;
    final normal = Offset(-unit.dy, unit.dx) * 5;
    final p1 = a + normal;
    final p2 = a - normal;
    final p3 = b - normal;
    final p4 = b + normal;
    return Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p4.dx, p4.dy)
      ..close();
  }

  /// Rounded shield outline: the defense powerup mark.
  static Path _shield() => Path()
    ..moveTo(50, 12)
    ..quadraticBezierTo(78, 20, 82, 30)
    ..lineTo(82, 48)
    ..quadraticBezierTo(82, 76, 50, 90)
    ..quadraticBezierTo(18, 76, 18, 48)
    ..lineTo(18, 30)
    ..quadraticBezierTo(22, 20, 50, 12)
    ..close();

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
