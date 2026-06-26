import 'package:flutter/material.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/durations.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/spacing.dart';

/// The in-progress word shown above the wheel while dragging.
class FormedWordPill extends StatelessWidget {
  const FormedWordPill({super.key, required this.word});
  final String word;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: word.isEmpty ? 0 : 1,
      duration: AppDurations.fast,
      child: word.isEmpty
          ? const SizedBox(height: 40)
          : Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: const BoxDecoration(
                color: AppColors.tileBlue,
                borderRadius: AppRadii.pill,
              ),
              child: Text(
                word,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: AppColors.tileBlueText,
                ),
              ),
            ),
    );
  }
}
