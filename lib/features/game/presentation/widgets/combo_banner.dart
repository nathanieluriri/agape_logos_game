import 'package:flutter/material.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/gradients.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/shadows.dart';
import '../../../../core/design/tokens/sizing.dart';
import '../../../../core/design/tokens/spacing.dart';

/// The "Praise! Combo Streak xN" banner; renders nothing below combo 2.
/// A lime-gold capsule tossed onto the water with a tiny playful tilt.
class ComboBanner extends StatelessWidget {
  const ComboBanner({super.key, required this.praise, required this.combo});
  final String? praise;
  final int combo;

  /// Slight counterclockwise lean, in radians.
  static const double _tiltRadians = -0.02;

  static const _decoration = BoxDecoration(
    gradient: AppGradients.progressFill,
    borderRadius: AppRadii.pill,
    boxShadow: AppShadows.pill,
  );

  @override
  Widget build(BuildContext context) {
    final label = praise;
    if (label == null) {
      return const SizedBox(height: AppSizing.comboBannerHeight);
    }
    return Transform.rotate(
      angle: _tiltRadians,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: _decoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            Text(
              'Combo Streak x$combo',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
