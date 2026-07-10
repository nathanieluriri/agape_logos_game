import 'package:flutter/material.dart';

import '../../../../core/design/motion/curves.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/durations.dart';
import '../../../../core/design/tokens/gradients.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/shadows.dart';
import '../../../../core/design/tokens/sizing.dart';
import '../../../../core/design/tokens/spacing.dart';

/// The in-progress word shown above the wheel while dragging: a lily-green
/// capsule floating on the water. Each letter pops in as it is added (a
/// left-to-right build), and the whole capsule fades as it appears and clears.
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

  // PLAN: keeping letterSpacing: 2 on each per-letter Text approximates the
  // old single-Text kerning; formed_word_pill.png may shift by sub-pixels. If
  // the letters read too tight or loose on-device, adjust letterSpacing here.
  static const _letterStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: 2,
    color: AppColors.padLabel,
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < word.length; i++)
                    _PillLetter(
                      // Keyed by position so only the newly appended letter
                      // pops; letters already on screen keep their place.
                      key: ValueKey<int>(i),
                      char: word[i],
                      animate: !reduceMotion,
                    ),
                ],
              ),
            ),
    );
  }
}

/// A single capsule letter that pops in the first time it appears.
class _PillLetter extends StatelessWidget {
  const _PillLetter({
    super.key,
    required this.char,
    required this.animate,
  });

  final String char;
  final bool animate;

  /// Scale the letter pops in from (the overshoot comes from the curve).
  static const double _popFrom = 0.4;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: _popFrom, end: 1),
      duration: animate ? AppDurations.instant : Duration.zero,
      curve: AppCurves.pop,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Text(char, style: FormedWordPill._letterStyle),
    );
  }
}
