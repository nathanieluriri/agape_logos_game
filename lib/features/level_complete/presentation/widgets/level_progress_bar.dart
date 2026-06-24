// lib/features/level_complete/presentation/widgets/level_progress_bar.dart
import 'package:flutter/material.dart';

import '../../../../core/design/motion/curves.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/durations.dart';
import '../../../../core/design/tokens/gradients.dart';
import '../../../../core/design/tokens/shadows.dart';
import '../../../../core/design/tokens/sizing.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../core/design/tokens/typography.dart';

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
            fontSize: 21,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: AppSizing.progressTrackWidth,
          height: AppSizing.progressTrackHeight,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: AppColors.progressTrack,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.progressTrackBorder, width: 3),
            boxShadow: AppShadows.track,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              duration: AppDurations.slow,
              curve: AppCurves.emphasized,
              tween: Tween(begin: 0, end: fraction.clamp(0, 1)),
              builder: (context, value, _) => FractionallySizedBox(
                widthFactor: value == 0 ? 0.0001 : value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppGradients.progressFill,
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
            ),
          ),
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
