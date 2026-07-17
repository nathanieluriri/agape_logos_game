import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design/motion/curves.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/durations.dart';

/// The armed shield: a translucent bubble over the letter wheel. Rising edge
/// blooms it in (elastic scale, rim sweep); while armed it is a STATIC frame
/// (no ticker, per the jank guardrails); the falling edge (shield consumed by
/// an incoming attack, or expired server-side) ripples and dissolves it.
/// Reduced motion: plain appear/disappear of the static frame.
class ShieldBubbleOverlay extends StatefulWidget {
  const ShieldBubbleOverlay({super.key, required this.armed, this.charges = 1});

  final bool armed;

  /// Armed shield count (Project B): 2+ draws a second concentric rim.
  final int charges;

  @override
  State<ShieldBubbleOverlay> createState() => _ShieldBubbleOverlayState();
}

class _ShieldBubbleOverlayState extends State<ShieldBubbleOverlay> {
  /// True while the falling-edge pop is still on screen.
  bool _popping = false;

  /// Bumped on every falling edge; a re-arm also bumps it so a delayed
  /// callback from a stale pop can recognize it is no longer current and
  /// skip clearing `_popping` out from under a newer pop (overlapping
  /// disarm/re-arm/disarm within one pop window would otherwise let the
  /// first callback truncate the second pop early).
  int _popSeq = 0;

  @override
  void didUpdateWidget(ShieldBubbleOverlay old) {
    super.didUpdateWidget(old);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (old.armed && !widget.armed && !reduceMotion) {
      // Falling edge: consumed or expired. Start (or restart) the pop.
      _popSeq++;
      final seq = _popSeq;
      setState(() => _popping = true);
      Future<void>.delayed(AppDurations.effectExpire, () {
        if (mounted && _popSeq == seq) setState(() => _popping = false);
      });
    } else if (!old.armed && widget.armed) {
      // Rising edge: re-armed, possibly mid-pop from a prior disarm. Kill
      // the stale pop instantly (invalidating any in-flight delayed
      // callback via the bumped sequence) so build() renders the bloom, not
      // a dissolving bubble for a shield that is once again active.
      _popSeq++;
      if (_popping) setState(() => _popping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!widget.armed && !_popping) return const SizedBox.shrink();
    final charges = math.max(1, widget.charges);

    Widget bubble;
    // `widget.armed` wins over `_popping`: a re-arm clears `_popping` in
    // didUpdateWidget (rising edge, above), but that setState and this
    // build can interleave with an in-flight delayed pop-clear callback, so
    // build() itself must also prefer the armed branch whenever both are
    // momentarily true rather than trust `_popping` alone.
    if (widget.armed) {
      if (reduceMotion) {
        bubble = CustomPaint(
          size: Size.infinite,
          painter: _ShieldPainter(bloom: 1, pop: 0, charges: charges),
        );
      } else {
        // Bloom runs once on mount of the armed state; TweenAnimationBuilder
        // holds the final static frame afterwards with no ticker.
        bubble = TweenAnimationBuilder<double>(
          key: const ValueKey<bool>(false),
          tween: Tween(begin: 0, end: 1),
          duration: AppDurations.effectLand,
          curve: AppCurves.pop,
          builder: (_, t, _) => CustomPaint(
            size: Size.infinite,
            painter: _ShieldPainter(bloom: t, pop: 0, charges: charges),
          ),
        );
      }
    } else {
      // Not armed: the early return above guarantees `_popping` is true
      // here.
      //
      // Phase-keyed: without a distinct key, flipping `_popping` reuses the
      // bloom TweenAnimationBuilder's element (same type, same
      // Tween(begin: 0, end: 1) shape). The bloom phase's tween has already
      // settled at t == 1, so ImplicitlyAnimatedWidgetState's forEachTween
      // sees no target change and never restarts the controller: the pop's
      // t stays pinned at 1 and `_ShieldPainter(bloom: 1, pop: 1, ...)`
      // (fade == 0) paints nothing for the whole exit window. A distinct
      // key per phase forces a fresh element/controller so the pop actually
      // sweeps 0 -> 1.
      bubble = TweenAnimationBuilder<double>(
        key: const ValueKey<bool>(true),
        tween: Tween(begin: 0, end: 1),
        duration: AppDurations.effectExpire,
        curve: AppCurves.exit,
        builder: (_, t, _) => CustomPaint(
          size: Size.infinite,
          painter: _ShieldPainter(bloom: 1, pop: t, charges: charges),
        ),
      );
    }
    return IgnorePointer(child: RepaintBoundary(child: bubble));
  }
}

/// [bloom] 0..1 scales the bubble in; [pop] 0..1 expands and fades it out.
class _ShieldPainter extends CustomPainter {
  const _ShieldPainter({
    required this.bloom,
    required this.pop,
    required this.charges,
  });

  final double bloom;
  final double pop;
  final int charges;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final base = size.shortestSide / 2 - 2;
    final radius = base * (0.8 + 0.2 * bloom) * (1 + 0.25 * pop);
    final fade = (1 - pop) * bloom;
    if (fade <= 0) return;

    // Soft dome fill.
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = AppColors.frostFill.withValues(alpha: 0.12 * fade),
    );
    // Iridescent rim: a sweep between frost white and lily green.
    final rimRect = Rect.fromCircle(center: center, radius: radius);
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..shader = SweepGradient(
        colors: [
          AppColors.frostBorder.withValues(alpha: 0.9 * fade),
          AppColors.lilyGreenLight.withValues(alpha: 0.5 * fade),
          AppColors.accent.withValues(alpha: 0.6 * fade),
          AppColors.frostBorder.withValues(alpha: 0.9 * fade),
        ],
      ).createShader(rimRect);
    canvas.drawCircle(center, radius, rim);
    // A second charge reads as a concentric inner rim.
    if (charges >= 2) canvas.drawCircle(center, radius - 8, rim);
  }

  @override
  bool shouldRepaint(_ShieldPainter old) =>
      old.bloom != bloom || old.pop != pop || old.charges != charges;
}
