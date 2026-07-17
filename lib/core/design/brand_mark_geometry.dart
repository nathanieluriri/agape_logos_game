// lib/core/design/brand_mark_geometry.dart
import 'dart:math' as math;
import 'dart:ui';

/// Shared geometry for the app's brand mark, authored in a 100x100 viewBox.
///
/// The mark is five pieces: a 2x2 grid of ivory-framed pink lotus tiles plus a
/// crimson lotus-bud keystone tucked into the top-left corner. It is the single
/// source of truth for both the static [BrandMark] logo and the animated splash
/// (each of the five pieces is a "block" that tumbles into place).
///
/// Piece indices: 0 = top-left, 1 = top-right, 2 = bottom-left,
/// 3 = bottom-right tile, 4 = crimson bud.
abstract final class BrandMarkGeometry {
  const BrandMarkGeometry._();

  static const double viewBox = 100;
  static const Offset center = Offset(50, 50);

  /// The four pink tiles.
  static const double tileSize = 39;
  static const double tileRadius = 11;

  /// The crimson keystone, overlapping the top-left tile's corner.
  static const double budLeft = 2.5;
  static const double budTop = 2.5;
  static const double budSize = 29;
  static const double budRadius = 9;

  /// Thickness of the ivory frame around every tile, and the inset corner
  /// radius of the pink field it surrounds.
  static const double frame = 3.4;
  static const double innerRadius = 8;

  /// Top-left corners of the four pink tiles (piece indices 0..3).
  static const List<Offset> tileOrigins = <Offset>[
    Offset(8.5, 8.5),
    Offset(52.5, 8.5),
    Offset(8.5, 52.5),
    Offset(52.5, 52.5),
  ];

  /// Outer (ivory) rectangle of tile [index] (0..3).
  static Rect tileRect(int index) =>
      Rect.fromLTWH(tileOrigins[index].dx, tileOrigins[index].dy, tileSize, tileSize);

  /// Outer (ivory) rectangle of the crimson bud keystone.
  static Rect get budRect =>
      const Rect.fromLTWH(budLeft, budTop, budSize, budSize);

  /// Home center of piece [index] (0..3 tiles, 4 bud) in the viewBox.
  static Offset pieceCenter(int index) =>
      index == 4 ? budRect.center : tileRect(index).center;

  /// A lotus rosette that decorates the pink field of a tile: eight radiating
  /// teardrop petals over a small inner ring. Built for [tile]'s inner square.
  static Path petalRosette(Rect tile) {
    final Offset c = tile.center;
    final double petalLen = tile.width * 0.30;
    final double petalWid = tile.width * 0.11;
    final Path path = Path();
    for (var i = 0; i < 8; i++) {
      final double a = i * math.pi / 4;
      _addPetal(path, c, a, petalLen, petalWid);
    }
    // Inner ring the petals spring from.
    path.addOval(Rect.fromCircle(center: c, radius: tile.width * 0.11));
    return path;
  }

  static void _addPetal(
      Path path, Offset c, double angle, double len, double wid) {
    final Offset dir = Offset(math.cos(angle), math.sin(angle));
    final Offset perp = Offset(-dir.dy, dir.dx);
    final Offset tip = c + dir * len;
    final Offset mid = c + dir * (len * 0.5);
    path
      ..moveTo(c.dx, c.dy)
      ..quadraticBezierTo(
          mid.dx + perp.dx * wid, mid.dy + perp.dy * wid, tip.dx, tip.dy)
      ..quadraticBezierTo(
          mid.dx - perp.dx * wid, mid.dy - perp.dy * wid, c.dx, c.dy)
      ..close();
  }

  /// An upright lotus bud (a tall center petal flanked by two shorter side
  /// petals) sitting inside the crimson keystone's inner square [field].
  static Path lotusBud(Rect field) {
    final double w = field.width;
    final double h = field.height;
    final double cx = field.center.dx;
    final double baseY = field.top + h * 0.82;
    final Path path = Path();
    // Center petal.
    path
      ..moveTo(cx, field.top + h * 0.12)
      ..cubicTo(cx - w * 0.20, field.top + h * 0.42, cx - w * 0.14, baseY,
          cx, baseY)
      ..cubicTo(cx + w * 0.14, baseY, cx + w * 0.20, field.top + h * 0.42, cx,
          field.top + h * 0.12)
      ..close();
    // Two side petals, splayed out from the base.
    for (final double s in const <double>[-1, 1]) {
      final double tipX = cx + s * w * 0.30;
      path
        ..moveTo(cx, baseY)
        ..cubicTo(cx + s * w * 0.10, field.top + h * 0.40, tipX,
            field.top + h * 0.44, tipX, field.top + h * 0.56)
        ..cubicTo(tipX, baseY - h * 0.06, cx + s * w * 0.10, baseY, cx, baseY)
        ..close();
    }
    return path;
  }
}
