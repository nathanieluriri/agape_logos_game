// lib/features/level_complete/presentation/pages/level_complete_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/play_flow.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../features/player/application/player_controller.dart';
import '../../../../features/profile/application/profile_providers.dart';
import '../../../../shared/widgets/coming_soon_sheet.dart';
import '../../../../shared/widgets/film_play_icon.dart';
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
                onAddCoins: () => showComingSoon(context, 'Store'),
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
                onPlay: () => startPlayFlow(context, ref),
                secondaryIcon: const FilmPlayIcon(size: 30),
                secondaryLabel: 'Bonus Gift',
                onSecondary: () => showComingSoon(context, 'Bonus Gift'),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
