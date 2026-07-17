import 'package:flutter/material.dart';

import '../../../../core/design/motion/curves.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/durations.dart';
import '../../../../core/design/tokens/gradients.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/shadows.dart';
import '../../../../core/design/tokens/sizing.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../core/design/tokens/typography.dart';

/// The "Praise! Combo Streak xN" banner; renders nothing below combo 2.
/// A lime-gold capsule tossed onto the water with a tiny playful tilt.
///
/// Each time the combo climbs, the capsule pops in with a springy overshoot so
/// a growing streak reads as an escalating reward (paired with the streak
/// haptic). Reserving the slot height while empty keeps the wheel from jumping
/// as the banner comes and goes. Tap or swipe it to dismiss; the next streak
/// beat brings it back.
class ComboBanner extends StatefulWidget {
  const ComboBanner({super.key, required this.praise, required this.combo});
  final String? praise;
  final int combo;

  @override
  State<ComboBanner> createState() => _ComboBannerState();
}

class _ComboBannerState extends State<ComboBanner> {
  /// Slight counterclockwise lean, in radians.
  static const double _tiltRadians = -0.02;

  /// Pop lands slightly larger than rest so higher streaks feel bigger.
  static const double _popFrom = 0.6;

  /// The capsule drops in from a few px above as it pops (logical px, eased to 0).
  // PLAN: _dropFrom and the AppDurations.normal duration are the feel knobs;
  // keep the drop small so the banner does not shove the wheel.
  static const double _dropFrom = -10;

  static const _decoration = BoxDecoration(
    gradient: AppGradients.progressFill,
    borderRadius: AppRadii.pill,
    boxShadow: AppShadows.pill,
  );

  /// The combo value the player dismissed. The banner stays hidden until a new
  /// streak beat (a different combo) supersedes it.
  int? _dismissedCombo;

  void _dismiss() {
    setState(() => _dismissedCombo = widget.combo);
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.praise;
    final dismissed = _dismissedCombo == widget.combo;
    if (label == null || dismissed) {
      return const SizedBox(height: AppSizing.comboBannerHeight);
    }
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
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
              style: AppTypography.banner.copyWith(color: AppColors.ink),
            ),
            Text(
              'Combo Streak x${widget.combo}',
              style: AppTypography.bannerSub.copyWith(color: AppColors.ink),
            ),
          ],
        ),
      ),
    );
    // Tap or swipe (a drag in any direction) dismisses the banner.
    final interactive = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _dismiss,
      onPanEnd: (_) => _dismiss(),
      child: Semantics(button: true, label: 'Dismiss combo', child: capsule),
    );
    if (reduceMotion) return interactive;
    // Keying by combo restarts the tween on every increment, so each new word
    // in the streak re-pops the capsule. No controller to manage.
    return TweenAnimationBuilder<double>(
      key: ValueKey<int>(widget.combo),
      tween: Tween<double>(begin: 0, end: 1),
      duration: AppDurations.normal,
      curve: AppCurves.pop,
      child: interactive,
      builder: (context, t, child) {
        // t is the pop-curved 0..1 (it overshoots past 1 mid-flight), so the
        // scale swells past rest and the drop settles with a tiny bounce.
        final scale = _popFrom + (1 - _popFrom) * t;
        final dy = _dropFrom * (1 - t);
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.scale(scale: scale, child: child),
        );
      },
    );
  }
}
