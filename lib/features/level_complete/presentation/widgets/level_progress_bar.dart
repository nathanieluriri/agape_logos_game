// lib/features/level_complete/presentation/widgets/level_progress_bar.dart
import 'package:flutter/material.dart';

import '../../../../core/design/motion/curves.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/durations.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../core/design/tokens/typography.dart';
import '../../../../shared/widgets/pond_progress_track.dart';

/// "Level N Completed!" label, an animated lime-gold track fill, and the serif
/// fraction. Used only on the level-complete page.
class LevelProgressBar extends StatelessWidget {
  const LevelProgressBar({
    super.key,
    required this.label,
    required this.fraction,
    required this.fractionText,
  });

  final String label;
  final double fraction;
  final String fractionText;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.padLabel,
            fontSize: 23,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TweenAnimationBuilder<double>(
          duration: AppDurations.slow,
          curve: AppCurves.emphasized,
          tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
          builder: (context, value, _) => PondProgressTrack(fraction: value),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          fractionText,
          style: AppTypography.numeral.copyWith(color: AppColors.progressFraction),
        ),
      ],
    );
  }
}
