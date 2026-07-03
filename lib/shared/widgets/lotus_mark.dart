// lib/shared/widgets/lotus_mark.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/design/motion/curves.dart';
import '../../core/design/tokens/durations.dart';
import '../../core/design/tokens/gradients.dart';
import '../../core/design/tokens/sizing.dart';

/// The pink lotus logo mark (SVG) floating over a soft oval water shadow.
/// The shadow stays on the surface while the flower bobs above it.
class LotusMark extends StatefulWidget {
  const LotusMark({super.key, this.width = AppSizing.lotusWidth, this.float = true});

  final double width;
  final bool float;

  @override
  State<LotusMark> createState() => _LotusMarkState();
}

class _LotusMarkState extends State<LotusMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: AppDurations.slow * 3);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (widget.float && !reduce && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (reduce || !widget.float) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// The lotus SVG viewBox is 200x150.
  static const double _svgAspect = 150 / 200;

  /// Extra room below the flower for the water shadow, as a width fraction.
  static const double _shadowRoom = 0.03;

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    final svg = SvgPicture.asset('assets/branding/lotus.svg', width: w);
    final Widget flower = widget.float
        ? AnimatedBuilder(
            animation: _c,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, -6 * AppCurves.float.transform(_c.value)),
              child: child,
            ),
            child: svg,
          )
        : svg;
    return SizedBox(
      width: w,
      height: w * (_svgAspect + _shadowRoom),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            bottom: 0,
            child: CustomPaint(
              size: Size(w * 0.62, w * 0.10),
              painter: const _WaterShadowPainter(),
            ),
          ),
          flower,
        ],
      ),
    );
  }
}

/// Paints the soft radial pool of shadowed water beneath the flower.
class _WaterShadowPainter extends CustomPainter {
  const _WaterShadowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // The radial shader is built on a square and squashed vertically so the
    // gradient fades to the ellipse edge instead of clipping to a circle.
    final side = size.width;
    final square = Rect.fromLTWH(0, 0, side, side);
    canvas
      ..save()
      ..scale(1, size.height / side)
      ..drawOval(
        square,
        Paint()..shader = AppGradients.lotusShadow.createShader(square),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(covariant _WaterShadowPainter oldDelegate) => false;
}
