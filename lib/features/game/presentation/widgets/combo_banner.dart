import 'package:flutter/material.dart';

import '../../../../core/design/motion/curves.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/durations.dart';
import '../../../../core/design/tokens/gradients.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/shadows.dart';
import '../../../../core/design/tokens/sizing.dart';
import '../../../../core/design/tokens/spacing.dart';

/// The "Praise! Combo Streak xN" banner; renders nothing below combo 2.
/// A lime-gold capsule tossed onto the water with a tiny playful tilt.
///
/// Each time the combo climbs, the capsule pops in with a springy overshoot so
/// a growing streak reads as an escalating reward (paired with the streak
/// haptic). Reserving the slot height while empty keeps the wheel from jumping
/// as the banner comes and goes.
class ComboBanner extends StatelessWidget {
  const ComboBanner({super.key, required this.praise, required this.combo});
  final String? praise;
  final int combo;

  /// Slight counterclockwise lean, in radians.
  static const double _tiltRadians = -0.02;

  /// Pop lands slightly larger than rest so higher streaks feel bigger.
  static const double _popFrom = 0.6;

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
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final capsule = Transform.rotate(
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
    if (reduceMotion) return capsule;
    // Keying by combo restarts the tween on every increment, so each new word
    // in the streak re-pops the capsule. No controller to manage.
    return TweenAnimationBuilder<double>(
      key: ValueKey<int>(combo),
      tween: Tween<double>(begin: _popFrom, end: 1),
      duration: AppDurations.fast,
      curve: AppCurves.pop,
      child: capsule,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
    );
  }
}
