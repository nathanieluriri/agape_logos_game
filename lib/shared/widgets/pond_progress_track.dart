// lib/shared/widgets/pond_progress_track.dart
import 'package:flutter/widgets.dart';

import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/gradients.dart';
import '../../core/design/tokens/shadows.dart';
import '../../core/design/tokens/sizing.dart';

/// The app's canonical progress track: a deep-water pill with a lime-gold fill.
/// One component, shared by the level-complete bar and the determinate loader,
/// so every filling bar in the app reads the same.
class PondProgressTrack extends StatelessWidget {
  const PondProgressTrack({
    super.key,
    required this.fraction,
    this.width = AppSizing.progressTrackWidth,
    this.height = AppSizing.progressTrackHeight,
  });

  /// Fill amount in the range 0..1 (clamped defensively).
  final double fraction;
  final double width;
  final double height;

  // Pill geometry (named so the two callers stay identical).
  static const double _trackRadius = 14;
  static const double _fillRadius = 9;
  static const double _innerPad = 2;
  static const double _borderWidth = 2;

  @override
  Widget build(BuildContext context) {
    final value = fraction.clamp(0.0, 1.0);
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(_innerPad),
      decoration: BoxDecoration(
        color: AppColors.progressTrack,
        borderRadius: BorderRadius.circular(_trackRadius),
        border: Border.all(
          color: AppColors.progressTrackBorder,
          width: _borderWidth,
        ),
        boxShadow: AppShadows.track,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          // A hair of width at zero so the rounded cap is always visible.
          widthFactor: value <= 0 ? 0.0001 : value,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppGradients.progressFill,
              borderRadius: BorderRadius.circular(_fillRadius),
            ),
          ),
        ),
      ),
    );
  }
}
