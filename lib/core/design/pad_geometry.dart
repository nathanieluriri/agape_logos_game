// lib/core/design/pad_geometry.dart
import 'dart:math' as math;
import 'dart:ui';

/// Shared lily-pad silhouette geometry, authored in a 100x100 viewBox.
///
/// Single source of truth for the pad outline: the interactive pad painter
/// (shared/widgets/lily_pad.dart) and the ambient submerged silhouettes
/// (game/ambient/pad_shadow_component.dart) both draw these paths.
///
/// The base silhouette is not a perfect circle: it is a three-sided shape
/// with corners so soft it reads as almost round, per the reference art.
abstract final class PadGeometry {
  const PadGeometry._();

  static const double viewBox = 100;
  static const Offset center = Offset(50, 50);
  static const double radius = 45;

  /// How much the three sides flatten toward the center (fraction of radius).
  static const double _sideDepth = 0.05;

  /// Smooth pad: the rounded-triangle base with no cuts (bonus/secondary).
  static final Path smoothPad = _base();

  /// The classic play pad: the base with a medium nick on one side
  /// (authored pointing +x; rotate at draw time) and a smaller nick on the
  /// opposite rim. Neither cut reaches the center.
  static final Path notchedPad = _cut(_base());

  /// Subtle radial vein texture, kept clear of both nicks.
  static final Path veins = _buildVeins();

  static double _r(double rad) =>
      radius * (1 - _sideDepth + _sideDepth * math.cos(3 * rad));

  static Offset _at(double deg, [double factor = 1]) {
    final rad = deg * math.pi / 180;
    return center +
        Offset(math.cos(rad), math.sin(rad)) * (_r(rad) * factor);
  }

  static Path _base() {
    const steps = 144;
    final path = Path();
    for (var i = 0; i <= steps; i++) {
      final p = _at(i / steps * 360);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  static Path _cut(Path base) {
    final cuts = Path()
      // Main nick on the +x side: ~17 units deep, well clear of the center.
      ..moveTo(center.dx + 26, center.dy)
      ..lineTo(_at(-7, 1.06).dx, _at(-7, 1.06).dy)
      ..lineTo(_at(7, 1.06).dx, _at(7, 1.06).dy)
      ..close()
      // Smaller nick on the opposite rim, ~10 units deep.
      ..moveTo(center.dx - 33, center.dy)
      ..lineTo(_at(174.5, 1.06).dx, _at(174.5, 1.06).dy)
      ..lineTo(_at(185.5, 1.06).dx, _at(185.5, 1.06).dy)
      ..close();

    return Path.combine(PathOperation.difference, base, cuts);
  }

  static Path _buildVeins() {
    final path = Path();
    for (final deg in const [30.0, 66.0, 103.0, 140.0, 220.0, 257.0, 294.0, 330.0]) {
      final rad = deg * math.pi / 180;
      final dir = Offset(math.cos(rad), math.sin(rad));
      final from = center + dir * 9;
      final to = center + dir * (_r(rad) - 9);
      path
        ..moveTo(from.dx, from.dy)
        ..lineTo(to.dx, to.dy);
    }
    return path;
  }
}
