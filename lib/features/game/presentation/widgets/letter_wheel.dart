import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design/tokens/colors.dart';
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
        widget.onTouch(i);
        break;
      }
    }
    setState(() => _finger = local);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSizing.wheelDiameter,
      height: AppSizing.wheelDiameter,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (d) => _hit(d.localPosition),
        onPanUpdate: (d) => _hit(d.localPosition),
        onPanEnd: (_) {
          setState(() => _finger = null);
          widget.onEnd();
        },
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _WheelPainter(
              centers: _centers,
              selected: widget.selected,
              finger: _finger,
            ),
            child: Stack(
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.wheelBase,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.expand(),
                ),
                for (var i = 0; i < widget.letters.length; i++)
                  Positioned(
                    left: _centers[i].dx - _node / 2,
                    top: _centers[i].dy - _node / 2,
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
      ),
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({required this.letter, required this.selected});
  final String letter;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        alignment: Alignment.center,
        decoration: selected
            ? const BoxDecoration(color: AppColors.tileBlue, shape: BoxShape.circle)
            : null,
        width: AppSizing.wheelNode,
        height: AppSizing.wheelNode,
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.tileBlueText : AppColors.wheelLetter,
          ),
        ),
      ),
    );
  }
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
      ..color = AppColors.connectLine
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
      old.finger != finger || old.selected.length != selected.length;
}
