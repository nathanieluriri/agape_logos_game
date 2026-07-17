// lib/shared/widgets/film_play_icon.dart
import 'package:flutter/widgets.dart';

import '../../core/design/tokens/colors.dart';

/// A filled filmstrip icon with punched sprocket holes and a play triangle,
/// matching the reference Bonus Gift art. The holes and the center strip are
/// cut out with BlendMode.clear so the pad color shows through them.
class FilmPlayIcon extends StatelessWidget {
  const FilmPlayIcon({super.key, this.size = 28, this.color = AppColors.padLabel});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.78),
      painter: _FilmPlayPainter(color),
    );
  }
}

class _FilmPlayPainter extends CustomPainter {
  const _FilmPlayPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fill = Paint()..color = color;
    final clear = Paint()..blendMode = BlendMode.clear;
    final band = h * 0.24;

    canvas.saveLayer(Offset.zero & size, Paint());

    // Filmstrip body.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h),
        Radius.circular(w * 0.12),
      ),
      fill,
    );

    // Punch the center strip.
    canvas.drawRect(Rect.fromLTRB(w * 0.06, band, w * 0.94, h - band), clear);

    // Punch three sprocket holes in the top and bottom bands.
    final holeW = w * 0.14;
    final holeH = band * 0.52;
    for (final cx in [w * 0.27, w * 0.5, w * 0.73]) {
      for (final cy in [band * 0.5, h - band * 0.5]) {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(cx, cy),
            width: holeW,
            height: holeH,
          ),
          clear,
        );
      }
    }

    // Play triangle in the center strip.
    final cy = h / 2;
    final tri = Path()
      ..moveTo(w * 0.42, cy - h * 0.15)
      ..lineTo(w * 0.62, cy)
      ..lineTo(w * 0.42, cy + h * 0.15)
      ..close();
    canvas.drawPath(tri, fill);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_FilmPlayPainter old) => old.color != color;
}
