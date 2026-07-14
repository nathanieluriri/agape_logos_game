// lib/shared/widgets/animated_app_icon.dart
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/design/motion/curves.dart';
import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/durations.dart';

/// The real app mark, drawing itself on a loop: a light rim sweeps around the
/// disc while the icon wipes in behind it, a soft halo blooms as it completes,
/// then it settles and repeats.
///
/// The artwork is `assets/branding/app_icon.svg` (the shaded lotus disc), so this
/// is the exact brand mark, not an approximation of it. It is drawn by an angular
/// mask rather than by stroking the source paths: the icon is 150+ FILLED shapes
/// with no outline, so stroke-tracing it would render as scribble. The sweep
/// reads as "being drawn" while keeping the real artwork intact.
///
/// Provider-free and self-contained, so the splash and the match countdown can
/// both use it. Honors reduced motion: the mark simply rests, fully drawn.
class AnimatedAppIcon extends StatefulWidget {
  const AnimatedAppIcon({super.key, required this.size});

  final double size;

  @override
  State<AnimatedAppIcon> createState() => _AnimatedAppIconState();
}

class _AnimatedAppIconState extends State<AnimatedAppIcon>
    with SingleTickerProviderStateMixin {
  static const String _asset = 'assets/branding/app_icon.svg';

  /// The halo is drawn outside the mark's own box.
  static const double _haloScale = 1.6;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: AppDurations.markDraw);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce) {
      _controller.stop();
      _controller.value = 1.0; // rest fully drawn
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _seg(double v, double a, double b, Curve curve) =>
      curve.transform(((v - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final double size = widget.size;
    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) {
            final double v = _controller.value;
            // The rim leads; the icon wipes in just behind it; the halo blooms as
            // the rim closes; everything settles before the loop restarts.
            final double rim = _seg(v, 0.00, 0.72, AppCurves.enter);
            final double wipe = _seg(v, 0.10, 0.82, AppCurves.enter);
            final double bloom = _seg(v, 0.62, 0.88, AppCurves.enter);
            final double settle = _seg(v, 0.88, 1.00, AppCurves.enter);
            // Bloom in, then ease back out so the loop closes on itself.
            final double halo = bloom * (1 - settle);
            final double lift = 1 + 0.04 * halo;

            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: <Widget>[
                _halo(size, halo),
                Transform.scale(
                  scale: lift,
                  child: ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (Rect bounds) =>
                        _sweepMask(bounds, wipe),
                    child: child, // the SVG: built once, not per frame
                  ),
                ),
                CustomPaint(
                  size: Size(size, size),
                  painter: _RimPainter(progress: rim, fade: 1 - settle),
                ),
              ],
            );
          },
          child: SvgPicture.asset(
            _asset,
            width: size,
            height: size,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  /// Angular reveal: everything the rim has already swept past is opaque, with a
  /// short feathered edge trailing it so the icon appears to be laid down rather
  /// than snapped on.
  Shader _sweepMask(Rect bounds, double progress) {
    const double feather = 0.06;
    final double head = progress.clamp(0.0, 1.0);
    // Fully drawn: a plain opaque mask (a sweep with stops at 1.0 would clip).
    if (head >= 1.0) {
      return const LinearGradient(
        colors: <Color>[Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
      ).createShader(bounds);
    }
    final double tail = math.max(0.0, head - feather);
    return SweepGradient(
      // Start at 12 o'clock so the draw begins at the top of the disc.
      transform: const GradientRotation(-math.pi / 2),
      colors: const <Color>[
        Color(0xFFFFFFFF), // drawn
        Color(0xFFFFFFFF),
        Color(0x00FFFFFF), // not yet drawn
        Color(0x00FFFFFF),
      ],
      stops: <double>[0.0, tail, head, 1.0],
    ).createShader(bounds);
  }

  Widget _halo(double size, double t) {
    if (t <= 0) return const SizedBox.shrink();
    final double side = size * _haloScale;
    return IgnorePointer(
      child: OverflowBox(
        maxWidth: side,
        maxHeight: side,
        child: Opacity(
          opacity: t * 0.55,
          child: SizedBox(
            width: side,
            height: side,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[AppColors.padRimGlow, Color(0x00FFFFFF)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The light rim that traces the disc edge, leading the reveal.
class _RimPainter extends CustomPainter {
  const _RimPainter({required this.progress, required this.fade});

  final double progress;
  final double fade;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || fade <= 0) return;
    // The disc does not touch the icon's edge; inset to sit on the rim itself.
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height)
        .deflate(size.width * 0.085);
    final double stroke = math.max(1.5, size.width * 0.018);
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = AppColors.padRimGlow.withValues(alpha: fade);

    canvas.drawArc(
      rect,
      -math.pi / 2, // start at 12 o'clock, matching the sweep
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RimPainter old) =>
      old.progress != progress || old.fade != fade;
}
