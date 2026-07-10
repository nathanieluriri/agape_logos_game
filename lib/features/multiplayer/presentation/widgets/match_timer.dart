import 'package:flutter/material.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/spacing.dart';

/// A mm:ss countdown to [endsAt], rendered against the page-owned [nowMillis]
/// clock (one ticker for the whole match: the timer, freeze expiry, and fog
/// expiry all read the same `now`). Turns urgent under ten seconds.
class MatchTimer extends StatelessWidget {
  const MatchTimer({super.key, required this.endsAt, required this.nowMillis});

  final int endsAt;
  final int nowMillis;

  @override
  Widget build(BuildContext context) {
    final remainingMs = (endsAt - nowMillis).clamp(0, 1 << 31);
    final totalSec = remainingMs ~/ 1000;
    final mm = (totalSec ~/ 60).toString().padLeft(2, '0');
    final ss = (totalSec % 60).toString().padLeft(2, '0');
    final urgent = totalSec <= 10;
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
        '$mm:$ss',
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
