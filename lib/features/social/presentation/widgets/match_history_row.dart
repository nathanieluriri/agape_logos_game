import 'package:flutter/widgets.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../domain/match_history_entry.dart';

/// One match-history row: a result chip, the opponent name, and the score line.
class MatchHistoryRow extends StatelessWidget {
  const MatchHistoryRow({super.key, required this.entry});

  final MatchHistoryEntry entry;

  Color get _chipColor => switch (entry.result) {
    'win' => AppColors.lilyGreenDeep,
    'loss' => AppColors.dangerFill,
    _ => AppColors.pillFill,
  };

  String get _chipLabel => switch (entry.result) {
    'win' => 'WON',
    'loss' => 'LOST',
    _ => 'DRAW',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: _chipColor,
              borderRadius: AppRadii.pill,
              border: Border.all(color: AppColors.settingsBorder),
            ),
            child: Text(
              _chipLabel,
              style: const TextStyle(
                color: AppColors.padLabel,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'vs ${entry.opponentName}',
              style: const TextStyle(
                color: AppColors.padLabel,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '${entry.score} - ${entry.opponentScore}',
            style: const TextStyle(
              color: AppColors.padLabelSoft,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
