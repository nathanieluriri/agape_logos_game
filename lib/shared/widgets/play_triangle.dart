// lib/shared/widgets/play_triangle.dart
import 'package:flutter/widgets.dart';

import '../../core/design/tokens/colors.dart';

/// The cream rounded play triangle on the Play pad: a softly rounded
/// right-pointing triangle with a slightly darker copy peeking out under the
/// bottom edge (the "pressed clay" extrusion from the reference).
class PlayTriangle extends StatelessWidget {
  const PlayTriangle({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 0.9, size),
      painter: const _PlayTrianglePainter(),
    );
  }
}

class _PlayTrianglePainter extends CustomPainter {
  const _PlayTrianglePainter();

  /// Right-pointing triangle with rounded corners.
  static Path _rounded(Size s, double r) {
    final pts = <Offset>[
      Offset.zero,
      Offset(s.width, s.height / 2),
      Offset(0, s.height),
    ];
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

  @override
  void paint(Canvas canvas, Size size) {
    final tri = _rounded(size, size.shortestSide * 0.22);

    // Extrusion: darker cream copy nudged down.
    canvas
      ..save()
      ..translate(0, size.height * 0.05)
      ..drawPath(tri, Paint()..color = AppColors.playTriangleShadow)
      ..restore()
      // Face.
      ..drawPath(tri, Paint()..color = AppColors.playTriangle);
  }

  @override
  bool shouldRepaint(covariant _PlayTrianglePainter oldDelegate) => false;
}
