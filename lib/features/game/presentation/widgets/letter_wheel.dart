import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/brand_mark_geometry.dart';
import '../../../../core/design/motion/curves.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/durations.dart';
import '../../../../core/design/tokens/gradients.dart';
import '../../../../core/design/tokens/shadows.dart';
import '../../../../core/design/tokens/sizing.dart';
import '../../../../core/haptics/haptics.dart';

/// Circular letter rack. The player drags across nodes to form a word.
/// Reports each newly entered node via [onTouch] and release via [onEnd].
class LetterWheel extends StatefulWidget {
  const LetterWheel({
    super.key,
    required this.letters,
    required this.selected,
    required this.onTouch,
    required this.onEnd,
    this.ids,
    this.swirlTick = 0,
  });

  final List<String> letters;
  final List<int> selected;
  final void Function(int slot) onTouch;
  final VoidCallback onEnd;

  /// Stable identity per slot (the session's rackOrder). Two builds that share
  /// an id for the same underlying letter let each letter animate from its old
  /// slot to its new one on a shuffle, instead of snapping. Defaults to slot
  /// index (identity permutation), so callers that don't shuffle get the old
  /// static layout.
  final List<int>? ids;

  /// Increment to make the next reorder swirl one full loop (scramble); plain
  /// shuffles keep the straight glide.
  final int swirlTick;

  /// Node centers for a wheel rendered at [size], first letter at 12 o'clock.
  ///
  /// The single source of truth for the wheel's slot geometry: the wheel
  /// itself lays nodes out with it, and the tutorial overlay reuses it to
  /// draw the guided trace over the on-screen wheel (passing the wheel's
  /// laid-out size, which may be scaled down by the page's FittedBox).
  static List<Offset> centersIn(Size size, int letterCount) {
    final radius = size.shortestSide / 2;
    final node =
        AppSizing.wheelNode * (size.shortestSide / AppSizing.wheelDiameter);
    final c = Offset(radius, radius);
    return [
      for (var i = 0; i < letterCount; i++)
        c +
            Offset.fromDirection(
              -math.pi / 2 + (2 * math.pi * i / letterCount),
              radius - node / 2,
            ),
    ];
  }

  @override
  State<LetterWheel> createState() => _LetterWheelState();
}

class _LetterWheelState extends State<LetterWheel>
    with SingleTickerProviderStateMixin {
  Offset? _finger;
  int? _lastSlot;

  static const double _node = AppSizing.wheelNode;

  /// Drives the scramble swirl: one loop from the old slot angle to the new
  /// one, over [AppDurations.scrambleSwirl]. Pointer input is ignored while
  /// this is animating.
  late final AnimationController _swirl = AnimationController(
    vsync: this,
    duration: AppDurations.scrambleSwirl,
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) setState(() {});
    });

  /// slotOfId snapshot from before the swirling reorder (id -> old slot).
  List<int>? _swirlFrom;

  /// slotOfId[id] = the slot this identity currently occupies. Iterating by
  /// id (stable order + stable key) means only the target position changes on
  /// a shuffle, which is exactly what drives the AnimatedPositioned glide.
  List<int> _slotOfId(List<int>? ids, int count) {
    final slotOfId = List<int>.generate(count, (i) => i);
    if (ids != null && ids.length == count) {
      for (var slot = 0; slot < count; slot++) {
        slotOfId[ids[slot]] = slot;
      }
    }
    return slotOfId;
  }

  @override
  void didUpdateWidget(LetterWheel old) {
    super.didUpdateWidget(old);
    if (widget.swirlTick == old.swirlTick) return;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) return;
    _swirlFrom = _slotOfId(old.ids, old.letters.length);
    _swirl.forward(from: 0);
  }

  @override
  void dispose() {
    _swirl.dispose();
    super.dispose();
  }

  /// Internally the wheel always renders at its fixed diameter, so the node
  /// scale inside [LetterWheel.centersIn] is exactly 1.
  List<Offset> get _centers => LetterWheel.centersIn(
    const Size(AppSizing.wheelDiameter, AppSizing.wheelDiameter),
    widget.letters.length,
  );

  void _hit(Offset local) {
    if (_swirl.isAnimating) return;
    final centers = _centers;
    for (var i = 0; i < centers.length; i++) {
      if ((centers[i] - local).distance <= _node / 2) {
        if (i != _lastSlot) {
          // A crisp tick per newly entered letter. Kept light (not a heavy
          // buzz) so a fast drag across the rack feels like discrete selections
          // rather than one long rumble.
          Haptics.instance.selectionClick();
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
    final count = widget.letters.length;
    // slotOfId[id] = the slot this identity currently occupies. Iterating by
    // id (stable order + stable key) means only the target position changes on
    // a shuffle, which is exactly what drives the AnimatedPositioned glide.
    final slotOfId = _slotOfId(widget.ids, count);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final moveDuration = reduceMotion ? Duration.zero : AppDurations.shuffle;
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
          if (!_swirl.isAnimating) widget.onEnd();
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
              if (_swirl.isAnimating &&
                  _swirlFrom != null &&
                  _swirlFrom!.length == count)
                AnimatedBuilder(
                  animation: _swirl,
                  builder: (_, _) {
                    const radius = AppSizing.wheelDiameter / 2;
                    const rim = radius - _node / 2;
                    const c = Offset(radius, radius);
                    double angleOf(int slot) =>
                        -math.pi / 2 + 2 * math.pi * slot / count;
                    return Stack(
                      children: [
                        for (var id = 0; id < count; id++)
                          () {
                            // Stagger: each letter launches slightly later.
                            final t = Interval(
                              (id * 0.05).clamp(0.0, 0.4),
                              1,
                              curve: AppCurves.emphasized,
                            ).transform(_swirl.value);
                            final from = angleOf(_swirlFrom![id]);
                            // One extra full loop on top of the slot delta.
                            final to = angleOf(slotOfId[id]) + 2 * math.pi;
                            final angle = from + (to - from) * t;
                            final pos =
                                c + Offset.fromDirection(angle, rim);
                            final lift =
                                1 + 0.08 * math.sin(math.pi * t);
                            return Positioned(
                              key: ValueKey<int>(id),
                              left: pos.dx - _node / 2,
                              top: pos.dy - _node / 2,
                              width: _node,
                              height: _node,
                              child: Transform.scale(
                                scale: lift,
                                child: _Node(
                                  letter: widget.letters[slotOfId[id]],
                                  selected: false,
                                ),
                              ),
                            );
                          }(),
                      ],
                    );
                  },
                )
              else
                ...[
                  for (var id = 0; id < count; id++)
                    AnimatedPositioned(
                      key: ValueKey<int>(id),
                      duration: moveDuration,
                      curve: AppCurves.emphasized,
                      left: centers[slotOfId[id]].dx - _node / 2,
                      top: centers[slotOfId[id]].dy - _node / 2,
                      width: _node,
                      height: _node,
                      child: _Node(
                        letter: widget.letters[slotOfId[id]],
                        selected: widget.selected.contains(slotOfId[id]),
                      ),
                    ),
                ],
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

  /// Selected nodes swell a touch so the active letters read as lifted.
  // PLAN: keep _selectedScale subtle (1.06) so the nodes do not collide.
  static const double _selectedScale = 1.06;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Center(
      child: AnimatedScale(
        scale: selected ? _selectedScale : 1,
        duration: reduceMotion ? Duration.zero : AppDurations.instant,
        curve: AppCurves.pop,
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
      ),
    );
  }
}

/// The cream paper pad under the letters: the lily-pad layer recipe (soft
/// cast shadow, hard underside, sheen fill, rim glow) on a plain circle, with a
/// faint gold lotus watermark bloomed in the middle so the pad reads as crafted
/// rather than blank. Stays a perfect circle for the drag hit-testing.
class _WheelBasePainter extends CustomPainter {
  const _WheelBasePainter();

  /// How far the darker underside peeks out below the disc (logical px).
  static const double _undersideDrop = 3;

  /// Rim glow stroke width.
  static const double _rimStroke = 2;

  /// Gold lotus watermark: how far the rosette bloom reaches (fraction of the
  /// pad radius), how visible it is, and the thin gold ring that encircles it.
  static const double _rosetteRadius = 0.62;
  static const double _watermarkAlpha = 0.15;
  static const double _goldRingRadius = 0.66;
  static const double _goldRingAlpha = 0.5;
  static const double _goldRingStroke = 1.6;

  /// Faint green lily-pad edge, drawn just inside the disc outline.
  static const double _greenRimInset = 1.5;
  static const double _greenRimAlpha = 0.35;
  static const double _greenRimStroke = 2;

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

    // 4. Gold lotus watermark: a faint rosette bloom in the middle, reusing the
    // brand mark's lotus geometry so the wheel carries the logo's flower motif,
    // ringed by a thin gold line. Both sit inside the letter nodes.
    final rosette = Rect.fromCircle(
      center: center,
      radius: radius * _rosetteRadius,
    );
    canvas.drawPath(
      BrandMarkGeometry.petalRosette(rosette),
      Paint()..color = AppColors.accent.withValues(alpha: _watermarkAlpha),
    );
    canvas.drawCircle(
      center,
      radius * _goldRingRadius,
      Paint()
        ..color = AppColors.accent.withValues(alpha: _goldRingAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _goldRingStroke,
    );

    // 5. Light rim glow, brightest along the top edge.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = AppGradients.padRimGlow.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _rimStroke,
    );

    // 6. Faint green lily-pad rim around the whole edge, under the top glow.
    canvas.drawCircle(
      center,
      radius - _greenRimInset,
      Paint()
        ..color = AppColors.lilyGreenLight.withValues(alpha: _greenRimAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _greenRimStroke,
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

  /// The bright core trail width.
  static const double _coreWidth = 10;

  /// The soft glow underlay: three progressively narrower, progressively less
  /// transparent stroke passes that stack into a falloff around the core. A
  /// MaskFilter.blur would be re-rasterized on every pointer-move frame (the
  /// trail follows the finger), which is the jank; layered strokes are the same
  /// look at stroke cost.
  // PLAN: the _glow* ladders shape the trail glow; nudge on-device so it reads
  // luminous but not muddy.
  static const List<double> _glowWidths = [18, 14.5, 12];
  static const List<double> _glowAlphas = [0.10, 0.13, 0.17];

  /// Stroke passes are geometry-independent, so they are built once for the
  /// whole app rather than per paint (jank rule: no per-frame allocations).
  static final List<Paint> _glowPaints = [
    for (var i = 0; i < _glowWidths.length; i++)
      Paint()
        ..color = AppColors.wheelConnect.withValues(alpha: _glowAlphas[i])
        ..strokeWidth = _glowWidths[i]
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
  ];

  static final Paint _corePaint = Paint()
    ..color = AppColors.wheelConnect
    ..strokeWidth = _coreWidth
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    if (selected.isEmpty) return;
    final path = Path()
      ..moveTo(centers[selected.first].dx, centers[selected.first].dy);
    for (final slot in selected.skip(1)) {
      path.lineTo(centers[slot].dx, centers[slot].dy);
    }
    if (finger != null) path.lineTo(finger!.dx, finger!.dy);

    for (final glow in _glowPaints) {
      canvas.drawPath(path, glow);
    }
    canvas.drawPath(path, _corePaint);
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.finger != finger || !listEquals(old.selected, selected);
}
