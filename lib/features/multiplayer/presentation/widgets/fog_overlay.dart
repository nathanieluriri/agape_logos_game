import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/durations.dart';

/// Blurs its [child] (the word board) while a fog effect is [active]. The
/// BackdropFilter is only in the tree while the fog is showing or fading out: a
/// mounted BackdropFilter costs a saveLayer of everything beneath it on every
/// frame (the wheel drag included), even at zero opacity. Reduced motion
/// replaces it with a flat fog scrim (no blur, no fade): same "you cannot read
/// the board" outcome, zero backdrop cost, no motion.
class FogOverlay extends StatefulWidget {
  const FogOverlay({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  // PLAN: on device, confirm the fog BackdropFilter (sigma 6) does not jank the
  // wheel drag underneath; if it does, lower the sigma.
  static const double _blurSigma = 6;

  @override
  State<FogOverlay> createState() => _FogOverlayState();
}

class _FogOverlayState extends State<FogOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: AppDurations.normal,
    value: widget.active ? 1 : 0,
  );

  @override
  void didUpdateWidget(FogOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      widget.active ? _fade.forward() : _fade.reverse();
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Stack(
      children: <Widget>[
        widget.child,
        if (reduceMotion)
          if (widget.active)
            const Positioned.fill(child: ColoredBox(color: AppColors.fogTint))
          else
            const SizedBox.shrink()
        else
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _fade,
              builder: (context, _) {
                final double opacity = _fade.value;
                if (opacity <= 0) return const SizedBox.shrink();
                return IgnorePointer(
                  ignoring: !widget.active,
                  child: Opacity(
                    opacity: opacity,
                    child: RepaintBoundary(
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(
                            sigmaX: FogOverlay._blurSigma,
                            sigmaY: FogOverlay._blurSigma,
                          ),
                          child: const ColoredBox(color: AppColors.fogTint),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
