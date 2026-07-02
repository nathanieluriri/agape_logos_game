import 'package:flutter/material.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/durations.dart';
import '../../../../core/design/tokens/gradients.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/shadows.dart';
import '../../../../core/design/tokens/sizing.dart';
import '../../../../core/design/tokens/spacing.dart';

/// The in-progress word shown above the wheel while dragging: a lily-green
/// capsule floating on the water.
class FormedWordPill extends StatelessWidget {
  const FormedWordPill({super.key, required this.word});
  final String word;

  static const _decoration = BoxDecoration(
    gradient: AppGradients.lilyGreen,
    borderRadius: AppRadii.pill,
    border: Border.fromBorderSide(
      BorderSide(color: AppColors.plusButtonBorder, width: 2),
    ),
    boxShadow: AppShadows.pill,
  );

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedOpacity(
      opacity: word.isEmpty ? 0 : 1,
      duration: reduceMotion ? Duration.zero : AppDurations.fast,
      child: word.isEmpty
          ? const SizedBox(height: AppSizing.pillHeight)
          : Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: _decoration,
              child: Text(
                word,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: AppColors.padLabel,
                ),
              ),
            ),
    );
  }
}
