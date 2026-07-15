import 'package:flutter/material.dart';

import '../../../../core/design/tokens/colors.dart';
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

  static int? _secondsLeft(DateTime? until, int now) {
    if (until == null) return null;
    final ms = until.millisecondsSinceEpoch - now;
    return ms > 0 ? (ms / 1000).ceil() : null;
  }

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    final fogLeft = _secondsLeft(effects.fogUntil, nowMillis);
    if (effects.fog && fogLeft != null) {
      chips.add(_EffectChip(label: 'Fog ${fogLeft}s', icon: Icons.blur_on));
    }

    final freezeLeft = _secondsLeft(effects.freezeUntil, nowMillis);
    if (effects.frozenLetter != null && freezeLeft != null) {
      chips.add(
        _EffectChip(
          label: 'Frozen ${freezeLeft}s',
          icon: Icons.ac_unit_rounded,
        ),
      );
    }

    if (effects.doublePoints) {
      chips.add(const _EffectChip(label: '2x points', icon: Icons.stars_rounded));
    }

    final wardLeft = _secondsLeft(effects.wardUntil, nowMillis);
    if (effects.warded && wardLeft != null) {
      chips.add(
        _EffectChip(label: 'Warded ${wardLeft}s', icon: Icons.security_rounded),
      );
    }

    if (effects.shieldArmed) {
      chips.add(const _EffectChip(label: 'Shield', icon: Icons.shield_rounded));
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

class _EffectChip extends StatelessWidget {
  const _EffectChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.pillFill,
        borderRadius: AppRadii.pill,
        border: Border.all(color: AppColors.pillBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.padLabel),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.pillText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
