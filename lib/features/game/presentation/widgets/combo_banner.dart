import 'package:flutter/material.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/spacing.dart';

/// The "Praise! Combo Streak xN" banner; renders nothing below combo 2.
class ComboBanner extends StatelessWidget {
  const ComboBanner({super.key, required this.praise, required this.combo});
  final String? praise;
  final int combo;

  @override
  Widget build(BuildContext context) {
    final label = praise;
    if (label == null) return const SizedBox(height: 52);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.comboBannerStart, AppColors.comboBannerEnd],
        ),
        borderRadius: AppRadii.card,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.tileBlueText,
            ),
          ),
          Text(
            'Combo Streak x$combo',
            style: const TextStyle(fontSize: 14, color: AppColors.tileBlueText),
          ),
        ],
      ),
    );
  }
}
