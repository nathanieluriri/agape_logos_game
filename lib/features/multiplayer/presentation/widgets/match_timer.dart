import 'package:flutter/material.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/spacing.dart';

/// A countdown to [endsAt], rendered against the page-owned [nowMillis] clock
/// (one ticker for the whole match: the timer, freeze expiry, and fog expiry
/// all read the same `now`). Under one hour remaining this shows `m:ss`
/// (e.g. `5:59`); at or over one hour it switches to `h:mm` (e.g. `5h 47m`),
/// since async matches run up to 6 hours and a raw minute count is unreadable.
/// Turns urgent under thirty seconds.
class MatchTimer extends StatelessWidget {
  const MatchTimer({super.key, required this.endsAt, required this.nowMillis});

  final int endsAt;
  final int nowMillis;

  static const int _urgentThresholdSec = 30;
  static const int _hourInSec = 3600;

  @override
  Widget build(BuildContext context) {
    final remainingMs = (endsAt - nowMillis).clamp(0, 1 << 31);
    final totalSec = remainingMs ~/ 1000;
    final urgent = totalSec <= _urgentThresholdSec;
    final label = totalSec >= _hourInSec
        ? '${totalSec ~/ _hourInSec}h ${((totalSec % _hourInSec) ~/ 60).toString().padLeft(2, '0')}m'
        : '${totalSec ~/ 60}:${(totalSec % 60).toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: urgent ? AppColors.dangerFill : AppColors.pillFill,
        borderRadius: AppRadii.pill,
        border: Border.all(
          color: urgent ? AppColors.dangerBorder : AppColors.settingsBorder,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: urgent ? AppColors.dangerOnPond : AppColors.pillText,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
