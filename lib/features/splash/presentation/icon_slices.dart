// lib/features/splash/presentation/icon_slices.dart
import 'package:flutter/widgets.dart';

/// Cuts the exact app icon (`assets/branding/app_icon.png`) into the five design
/// blocks the splash reassembles: the four quadrant tiles and the crimson
/// lotus-bud keystone in the top-left corner.
///
/// Every block draws the whole icon but clipped to its region, so when all five
/// sit at their home position they reconstruct the artwork pixel-perfectly. The
/// quadrant cuts run along the mullion cross between the tiles, so the seams
/// fall in the gaps and are invisible. All boundaries are fractions of the
/// (square) icon box, kept here so they are easy to tune to the exact art.
abstract final class IconSlices {
  const IconSlices._();

  static const int pieceCount = 5;

  /// Mullion cross: where the 2x2 grid splits (fraction of the box).
  static const double splitX = 0.5;
  static const double splitY = 0.5;

  /// The crimson bud keystone square (fractions of the box), cut out of the
  /// top-left quadrant and dropped in last.
  static const Rect budFraction = Rect.fromLTRB(0.235, 0.215, 0.375, 0.355);

  /// Pivot (as a fraction of the box) each block rotates about while it tumbles
  /// in: roughly the visual centre of its tile.
  static const List<Offset> _pivotFraction = <Offset>[
    Offset(0.37, 0.37), // 0 top-left tile
    Offset(0.63, 0.37), // 1 top-right tile
    Offset(0.37, 0.63), // 2 bottom-left tile
    Offset(0.63, 0.63), // 3 bottom-right tile
    Offset(0.305, 0.285), // 4 bud keystone
  ];

  /// The rotation pivot of block [index] expressed as an [Alignment].
  static Alignment alignment(int index) {
    final Offset f = _pivotFraction[index];
    return Alignment(f.dx * 2 - 1, f.dy * 2 - 1);
  }

  static CustomClipper<Path> clipper(int index) => _SliceClipper(index);
}

class _SliceClipper extends CustomClipper<Path> {
  const _SliceClipper(this.index);

  final int index;

  @override
  Path getClip(Size size) {
    final double w = size.width;
    final double h = size.height;
    final double sx = IconSlices.splitX * w;
    final double sy = IconSlices.splitY * h;
    final Rect bud = Rect.fromLTRB(
      IconSlices.budFraction.left * w,
      IconSlices.budFraction.top * h,
      IconSlices.budFraction.right * w,
      IconSlices.budFraction.bottom * h,
    );
    switch (index) {
      case 1:
        return Path()..addRect(Rect.fromLTRB(sx, 0, w, sy));
      case 2:
        return Path()..addRect(Rect.fromLTRB(0, sy, sx, h));
      case 3:
        return Path()..addRect(Rect.fromLTRB(sx, sy, w, h));
      case 4:
        return Path()..addRect(bud);
      case 0:
      default:
        // Top-left quadrant with the bud keystone notched out.
        final Path quadrant = Path()..addRect(Rect.fromLTRB(0, 0, sx, sy));
        final Path budPath = Path()..addRect(bud);
        return Path.combine(PathOperation.difference, quadrant, budPath);
    }
  }

  @override
  bool shouldReclip(_SliceClipper old) => old.index != index;
}
