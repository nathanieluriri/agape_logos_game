import 'package:flutter/material.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../domain/match_player.dart';

/// The opponent's live line: name, score, words found, and a left/here dot. All
/// values come from the match doc (server-authoritative), so it never trusts a
/// client-reported score.
class OpponentHud extends StatelessWidget {
  const OpponentHud({super.key, required this.opponent});

  final MatchPlayer? opponent;

  @override
  Widget build(BuildContext context) {
    final o = opponent;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.pillFill,
        borderRadius: AppRadii.pill,
        border: Border.all(color: AppColors.pillBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            (o?.connected ?? false) ? Icons.circle : Icons.circle_outlined,
            size: 10,
            color: (o?.connected ?? false)
                ? AppColors.lilyGreenLight
                : AppColors.padLabelSoft,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            o?.displayName ?? 'Waiting...',
            style: const TextStyle(
              color: AppColors.pillText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            '${o?.score ?? 0}',
            style: const TextStyle(
              color: AppColors.padLabel,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '(${o?.wordsFound ?? 0} words)',
            style: const TextStyle(color: AppColors.padLabelSoft, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
