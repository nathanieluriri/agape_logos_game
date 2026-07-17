import 'package:flutter/material.dart';

import '../../../../core/design/motion/curves.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/durations.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../application/match_providers.dart';

/// Remaining-seconds badges for whatever is live on ME right now, rendered
/// against the page-owned [nowMillis] clock (the same clock as `MatchTimer`,
/// the freeze overlay, and the fog overlay - see `match_page.dart`'s
/// `_Ticking`). A chip with no expiry (shield, armed until consumed) shows
/// with no countdown.
class ActiveEffectChips extends StatelessWidget {
  const ActiveEffectChips({
    super.key,
    required this.effects,
    required this.nowMillis,
  });

  final MatchActiveEffects effects;
  final int nowMillis;

  // NOTE: the timed chips (fog, freeze, ward) require BOTH the boolean/letter
  // flag AND a still-future `...Until` expiry. `activeEffectsProvider` always
  // sets the pair together for a live timed effect, so a flag without an
  // expiry (or a lapsed expiry the provider has not re-evaluated yet) renders
  // no chip rather than a countdown-less one.

  static int? _secondsLeft(DateTime? until, int now) {
    if (until == null) return null;
    final ms = until.millisecondsSinceEpoch - now;
    return ms > 0 ? (ms / 1000).ceil() : null;
  }

  /// A kind's stacks render as an `x$n` suffix once 2+ casts are live at
  /// once (Project B). A single stack (or a kind with no stack tracking
  /// yet) reads with no suffix, unchanged from before stacking existed.
  static String _stackedLabel(String base, int stacks) =>
      stacks >= 2 ? '$base x$stacks' : base;

  /// Danger styling kicks in for a timed chip's final [urgentThresholdSecs].
  static const urgentThresholdSecs = 5;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    final fogLeft = _secondsLeft(effects.fogUntil, nowMillis);
    if (effects.fog && fogLeft != null) {
      chips.add(_EffectChip(
        key: ValueKey('fog-${effects.fogStacks}'),
        label: '${_stackedLabel('Fog', effects.fogStacks)} ${fogLeft}s',
        icon: Icons.blur_on,
        urgent: fogLeft <= urgentThresholdSecs,
      ));
    }

    final freezeLeft = _secondsLeft(effects.freezeUntil, nowMillis);
    if (effects.frozenLetter != null && freezeLeft != null) {
      chips.add(_EffectChip(
        key: ValueKey('freeze-${effects.freezeStacks}'),
        label:
            '${_stackedLabel('Frozen', effects.freezeStacks)} ${freezeLeft}s',
        icon: Icons.ac_unit_rounded,
        urgent: freezeLeft <= urgentThresholdSecs,
      ));
    }

    final doublePointsLeft = _secondsLeft(effects.doublePointsUntil, nowMillis);
    if (effects.doublePoints && doublePointsLeft != null) {
      chips.add(_EffectChip(
        key: ValueKey('double-${effects.doublePointsStacks}'),
        label: '${_stackedLabel('2x points', effects.doublePointsStacks)} '
            '${doublePointsLeft}s',
        icon: Icons.stars_rounded,
        urgent: doublePointsLeft <= urgentThresholdSecs,
      ));
    }

    final wardLeft = _secondsLeft(effects.wardUntil, nowMillis);
    if (effects.warded && wardLeft != null) {
      chips.add(_EffectChip(
        key: ValueKey('ward-${effects.wardStacks}'),
        label: '${_stackedLabel('Warded', effects.wardStacks)} ${wardLeft}s',
        icon: Icons.security_rounded,
        urgent: wardLeft <= urgentThresholdSecs,
      ));
    }

    if (effects.shieldArmed) {
      chips.add(_EffectChip(
        key: ValueKey('shield-${effects.shieldCharges}'),
        label: _stackedLabel('Shield', effects.shieldCharges),
        icon: Icons.shield_rounded,
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();
    return RepaintBoundary(
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: chips,
      ),
    );
  }
}

/// A single status pill. Its widget [key] must be `kind-stacks` (never the
/// full label, which also carries the ticking seconds) so a countdown tick
/// rebuilds this same element in place - no key change, no remount, no
/// re-pop - while a stack-count change (a fresh cast landing on top of an
/// already-active effect) mints a new key, forcing a fresh mount that replays
/// the pop-in.
class _EffectChip extends StatelessWidget {
  const _EffectChip({
    super.key,
    required this.label,
    required this.icon,
    this.urgent = false,
  });

  final String label;
  final IconData icon;

  /// True inside the effect's final [ActiveEffectChips.urgentThresholdSecs]
  /// seconds; swaps the chip to danger styling as an expiry warning.
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final fg = urgent ? AppColors.dangerOnPond : AppColors.pillText;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1),
      duration: reduceMotion ? Duration.zero : AppDurations.fast,
      curve: AppCurves.pop,
      builder: (_, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: urgent ? AppColors.dangerFill : AppColors.pillFill,
          borderRadius: AppRadii.pill,
          border: Border.all(
            color: urgent ? AppColors.dangerBorder : AppColors.pillBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: urgent ? fg : AppColors.padLabel),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
