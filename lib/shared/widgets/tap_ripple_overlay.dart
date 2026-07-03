import 'package:flutter/material.dart';

import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/durations.dart';

/// App-wide water-tap effect: every pointer-down spawns a soft expanding ring
/// (a "drop on the pond") at the touch point. Purely decorative and never
/// absorbs the gesture, so buttons, drags, and scrolls keep working. Honors
/// reduced-motion (no ripple when animations are disabled).
///
/// Provider-free by design; wrap the app's navigator with it via the
/// `MaterialApp.router` builder.
class TapRippleOverlay extends StatefulWidget {
  const TapRippleOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<TapRippleOverlay> createState() => _TapRippleOverlayState();
}

class _TapRippleOverlayState extends State<TapRippleOverlay>
    with TickerProviderStateMixin {
  /// Cap concurrent ripples so a mash of taps can't spawn unbounded tickers.
  static const int _maxConcurrent = 12;

  final List<_Ripple> _ripples = <_Ripple>[];

  void _spawn(Offset position) {
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) return;

    final controller =
        AnimationController(vsync: this, duration: AppDurations.ripple);
    final ripple = _Ripple(center: position, controller: controller);
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (!mounted) return;
        setState(() => _ripples.remove(ripple));
        controller.dispose();
      }
    });

    setState(() {
      if (_ripples.length >= _maxConcurrent) {
        _ripples.removeAt(0).controller.dispose();
      }
      _ripples.add(ripple);
    });
    controller.forward();
  }

  @override
  void dispose() {
    for (final r in _ripples) {
      r.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) => _spawn(event.localPosition),
      child: Stack(
        children: [
          widget.child,
          if (_ripples.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _RipplePainter(
                      ripples: _ripples,
                      repaint: Listenable.merge(
                        [for (final r in _ripples) r.controller],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Ripple {
  _Ripple({required this.center, required this.controller});

  final Offset center;
  final AnimationController controller;
}

class _RipplePainter extends CustomPainter {
  _RipplePainter({required this.ripples, required Listenable repaint})
      : super(repaint: repaint);

  final List<_Ripple> ripples;

  /// How far the outer ring travels from the touch point (logical px).
  static const double _maxRadius = 130;

  @override
  void paint(Canvas canvas, Size size) {
    for (final r in ripples) {
      final double t = r.controller.value;
      final double fade = 1 - t;
      final Offset c = r.center;

      // Leading ring: expands fast, thins and fades as it goes.
      final double outer = Curves.easeOutCubic.transform(t) * _maxRadius;
      canvas.drawCircle(
        c,
        outer,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * (1 - t * 0.6)
          ..color = AppColors.padRimGlow.withValues(alpha: 0.55 * fade),
      );

      // Trailing ring: starts a beat later and lags behind, for a watery
      // double-ripple.
      final double t2 = ((t - 0.14) / 0.86).clamp(0.0, 1.0);
      if (t2 > 0) {
        final double inner = Curves.easeOutCubic.transform(t2) * _maxRadius * 0.78;
        canvas.drawCircle(
          c,
          inner,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = AppColors.wordmark.withValues(alpha: 0.30 * (1 - t2)),
        );
      }

      // Soft center bloom that fades quickly, like the splash point.
      final double bloom = Curves.easeOut.transform(t) * 26;
      canvas.drawCircle(
        c,
        bloom,
        Paint()
          ..color = AppColors.padRimGlow.withValues(alpha: 0.22 * fade * fade),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) =>
      !identical(oldDelegate.ripples, ripples);
}
