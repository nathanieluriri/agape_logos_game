import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/gradients.dart';
import '../../../../core/design/tokens/shadows.dart';
import '../../../../core/design/tokens/sizing.dart';

/// Circular letter rack. The player drags across nodes to form a word.
/// Reports each newly entered node via [onTouch] and release via [onEnd].
class LetterWheel extends StatefulWidget {
  const LetterWheel({
    super.key,
    required this.letters,
    required this.selected,
    required this.onTouch,
    required this.onEnd,
  });

  final List<String> letters;
  final List<int> selected;
  final void Function(int slot) onTouch;
  final VoidCallback onEnd;

  @override
  State<LetterWheel> createState() => _LetterWheelState();
}

class _LetterWheelState extends State<LetterWheel> {
  Offset? _finger;
  int? _lastSlot;

  static const double _radius = AppSizing.wheelDiameter / 2;
  static const double _node = AppSizing.wheelNode;

  List<Offset> get _centers {
    final n = widget.letters.length;
    const c = Offset(_radius, _radius);
    return [
      for (var i = 0; i < n; i++)
        c +
            Offset.fromDirection(
              -math.pi / 2 + (2 * math.pi * i / n),
              _radius - _node / 2,
            ),
    ];
  }

  void _hit(Offset local) {
    final centers = _centers;
    for (var i = 0; i < centers.length; i++) {
      if ((centers[i] - local).distance <= _node / 2) {
        if (i != _lastSlot) {
          widget.onTouch(i);
          _lastSlot = i;
        }
        break;
      }
    }
    setState(() => _finger = local);
  }

  @override
  Widget build(BuildContext context) {
    // Hoisted once per build: the getter allocates a fresh list, and the node
    // loop below reads it repeatedly (jank rule: no per-frame allocations).
    final centers = _centers;
    return SizedBox(
      width: AppSizing.wheelDiameter,
      height: AppSizing.wheelDiameter,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (d) {
          _lastSlot = null;
          _hit(d.localPosition);
        },
        onPanUpdate: (d) => _hit(d.localPosition),
        onPanEnd: (_) {
          _lastSlot = null;
          setState(() => _finger = null);
          widget.onEnd();
        },
        child: RepaintBoundary(
          child: Stack(
            children: [
              // The cream pad the letters float on, behind everything.
              const SizedBox.expand(
                child: CustomPaint(painter: _WheelBasePainter()),
              ),
              // The drag line: over the cream pad, under the letter nodes.
              Positioned.fill(
                child: CustomPaint(
                  painter: _WheelPainter(
                    centers: centers,
                    selected: widget.selected,
                    finger: _finger,
                  ),
                ),
              ),
              for (var i = 0; i < widget.letters.length; i++)
                Positioned(
                  left: centers[i].dx - _node / 2,
                  top: centers[i].dy - _node / 2,
                  width: _node,
                  height: _node,
                  child: _Node(
                    letter: widget.letters[i],
                    selected: widget.selected.contains(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({required this.letter, required this.selected});
  final String letter;
  final bool selected;

  /// Selected node: a mini lily pad lifted off the cream disc.
  static const _selectedDecoration = BoxDecoration(
    gradient: AppGradients.lilyGreen,
    shape: BoxShape.circle,
    boxShadow: AppShadows.pill,
  );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        alignment: Alignment.center,
        decoration: selected ? _selectedDecoration : null,
        width: AppSizing.wheelNode,
        height: AppSizing.wheelNode,
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.padLabel : AppColors.wheelLetter,
          ),
        ),
      ),
    );
  }
}

/// The cream paper pad under the letters: the lily-pad layer recipe (soft
/// cast shadow, hard underside, sheen fill, rim glow) on a plain circle, so
/// the wheel stays a perfect circle for the drag hit-testing.
class _WheelBasePainter extends CustomPainter {
  const _WheelBasePainter();

  /// How far the darker underside peeks out below the disc (logical px).
  static const double _undersideDrop = 3;

  /// Rim glow stroke width.
  static const double _rimStroke = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // 1. Soft cast shadow on the water.
    final cast = AppShadows.pad.first;
    canvas.drawCircle(
      center.translate(0, cast.offset.dy),
      radius,
      Paint()
        ..color = cast.color
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          Shadow.convertRadiusToSigma(cast.blurRadius),
        ),
    );

    // 2. Hard darker underside peeking out below the fill.
    canvas.drawCircle(
      center.translate(0, _undersideDrop),
      radius,
      Paint()..color = AppColors.wheelPadUnder,
    );

    // 3. Cream sheen fill (top-left light source).
    canvas.drawCircle(
      center,
      radius,
      Paint()..shader = AppGradients.wheelPad.createShader(rect),
    );

    // 4. Light rim glow, brightest along the top edge.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = AppGradients.padRimGlow.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _rimStroke,
    );
  }

  @override
  bool shouldRepaint(_WheelBasePainter oldDelegate) => false;
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({
    required this.centers,
    required this.selected,
    required this.finger,
  });

  final List<Offset> centers;
  final List<int> selected;
  final Offset? finger;

  @override
  void paint(Canvas canvas, Size size) {
    if (selected.isEmpty) return;
    final paint = Paint()
      ..color = AppColors.wheelConnect
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(centers[selected.first].dx, centers[selected.first].dy);
    for (final slot in selected.skip(1)) {
      path.lineTo(centers[slot].dx, centers[slot].dy);
    }
    if (finger != null) path.lineTo(finger!.dx, finger!.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.finger != finger || !listEquals(old.selected, selected);
}
