import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/durations.dart';

/// Blurs its [child] (the word board) while a fog effect is [active]. The blur
/// sits in its own RepaintBoundary so it does not repaint the board. Reduced
/// motion replaces the BackdropFilter with a flat fog scrim (no blur, no fade):
/// same "you cannot read the board" outcome, zero backdrop cost, no motion.
class FogOverlay extends StatelessWidget {
  const FogOverlay({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  // PLAN: on device, confirm the fog BackdropFilter (sigma 6) does not jank the
  // wheel drag underneath; if it does, lower the sigma.
  static const double _blurSigma = 6;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: reduceMotion
              ? IgnorePointer(
                  ignoring: !active,
                  child: ColoredBox(
                    color: active ? AppColors.fogTint : AppColors.transparent,
                  ),
                )
              : IgnorePointer(
                  ignoring: !active,
                  child: AnimatedOpacity(
                    opacity: active ? 1 : 0,
                    duration: AppDurations.normal,
                    child: RepaintBoundary(
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(
                            sigmaX: _blurSigma,
                            sigmaY: _blurSigma,
                          ),
                          child: const ColoredBox(color: AppColors.fogTint),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
