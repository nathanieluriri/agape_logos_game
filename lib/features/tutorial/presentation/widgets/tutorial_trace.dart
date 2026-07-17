import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path_drawing/path_drawing.dart';

import '../../../../core/design/tokens/colors.dart';

/// Linear position along the polyline through [points] at [t] in [0, 1],
/// measured over cumulative segment lengths. Used to place the tutorial hand
/// on the dashed guide as its loop animation progresses.
Offset positionAlong(List<Offset> points, double t) {
  assert(points.isNotEmpty);
  if (points.length == 1) return points.first;
  final clamped = t.clamp(0.0, 1.0);
  // Cumulative length at the end of each segment.
  var total = 0.0;
  final ends = <double>[];
  for (var i = 0; i < points.length - 1; i++) {
    total += (points[i + 1] - points[i]).distance;
    ends.add(total);
  }
  if (total == 0) return points.first;
  final target = clamped * total;
  var start = 0.0;
  for (var i = 0; i < ends.length; i++) {
    if (target <= ends[i] || i == ends.length - 1) {
      final segment = ends[i] - start;
      final f = segment == 0 ? 0.0 : (target - start) / segment;
      return Offset.lerp(points[i], points[i + 1], f)!;
    }
    start = ends[i];
  }
  return points.last;
}

/// Dashed guide path through the target word's letter centers on the wheel,
/// in soft paper white over the tutorial scrim.
class TutorialTracePainter extends CustomPainter {
  const TutorialTracePainter({required this.points});

  /// Ordered slot centers in overlay coordinates.
  final List<Offset> points;

  /// Dash-and-gap rhythm plus stroke weight of the guide line.
  static const double _dash = 12;
  static const double _gap = 10;
  static const double _stroke = 6;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }
    final dashed = dashPath(
      line,
      dashArray: CircularIntervalList<double>(const [_dash, _gap]),
    );
    canvas.drawPath(
      dashed,
      Paint()
        ..color = AppColors.tutorialTrace
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(TutorialTracePainter old) =>
      !listEquals(old.points, points);
}
