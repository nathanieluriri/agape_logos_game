// lib/features/level_complete/presentation/pages/level_complete_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/spacing.dart';
import '../../../../features/player/application/player_controller.dart';
import '../../../../features/profile/application/profile_providers.dart';
import '../../../../features/rewards/application/rewards_providers.dart';
import '../../../../features/rewards/domain/claim_result.dart';
import '../../../../features/rewards/presentation/cooldown_format.dart';
import '../../../../shared/widgets/film_play_icon.dart';
import '../../../../shared/widgets/pond_snack.dart';
import '../../../../shared/widgets/play_pad_cluster.dart';
import '../../../../shared/widgets/pond_background.dart';
import '../../../../shared/widgets/pond_stage.dart';
import '../../../../shared/widgets/pond_top_bar.dart';
import '../../../../shared/widgets/wordmark_logo.dart';
import '../widgets/level_progress_bar.dart';

/// The level-complete screen. Thin composition: header, wordmark, the progress
/// bar, and a play cluster with the Play pad and a Bonus pad. No withdraw.
class LevelCompletePage extends ConsumerWidget {
  const LevelCompletePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(coinsProvider);
    final summary = ref.watch(levelCompletionProvider);
    final completedLabel = summary?.completedLabel ?? '';
    final fraction = summary?.progressFraction ?? 0;
    final fractionText = summary?.fractionText ?? '0/0';
    final nextLabel = 'Lv.${ref.watch(nextLevelProvider)}';
    return Scaffold(
      body: PondBackground(
        child: PondStage(
          child: Column(
            children: [
              PondTopBar(
                coins: coins,
                onSettings: () => context.push('/settings'),
                onAddCoins: () => context.push('/store'),
              ),
              const SizedBox(height: AppSpacing.lg),
              const WordmarkLogo(),
              const SizedBox(height: AppSpacing.xl),
              LevelProgressBar(
                label: completedLabel,
                fraction: fraction,
                fractionText: fractionText,
              ),
              const Spacer(),
              PlayPadCluster(
                nextLabel: nextLabel,
                // Replace (not push) so Android back from the next level goes
                // straight Home, and the finished level cannot be replayed.
                onPlay: () => context.pushReplacement('/game'),
                secondaryIcon: const FilmPlayIcon(size: 30),
                secondaryLabel: 'Bonus Gift',
                onSecondary: () => _claimBonus(context, ref),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  /// Bonus Gift claims the recurring coin reward (the same one the home timer
  /// pad surfaces). The server enforces the 72h cooldown and the level gate, so
  /// this is a plain online claim: on success it celebrates, otherwise it
  /// explains why (cooldown countdown, still locked, or unreachable).
  Future<void> _claimBonus(BuildContext context, WidgetRef ref) async {
    final ClaimResult result =
        await ref.read(rewardStatusControllerProvider.notifier).claimCoins();
    if (!context.mounted) return;
    final String message = switch (result) {
      ClaimCoinsSuccess(:final claimed) => 'Bonus claimed! +$claimed coins',
      ClaimPowerupSuccess() => 'Bonus claimed!',
      ClaimOnCooldown(:final nextClaimInMs) =>
        'Next bonus in ${formatCooldownMs(nextClaimInMs)}',
      ClaimLocked(:final minLevel) => 'Bonus unlocks at Lv.$minLevel',
      ClaimUnavailable() => 'Could not reach the server. Try again.',
    };
    showPondSnack(context, message);
  }
}
