// lib/features/level_complete/presentation/pages/level_complete_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/play_flow.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/sizing.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../features/player/application/player_controller.dart';
import '../../../../shared/widgets/coming_soon_sheet.dart';
import '../../../../shared/widgets/lily_pad.dart';
import '../../../../shared/widgets/lily_pad_button.dart';
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
    final s = ref.watch(playerStateProvider);
    return Scaffold(
      body: PondBackground(
        child: PondStage(
          child: Column(
            children: [
              PondTopBar(
                coins: s.coins,
                onSettings: () => showComingSoon(context, 'Settings'),
                onAddCoins: () => showComingSoon(context, 'Store'),
              ),
              const SizedBox(height: AppSpacing.lg),
              const WordmarkLogo(),
              const SizedBox(height: AppSpacing.xl),
              LevelProgressBar(
                label: s.completedLabel,
                fraction: s.progressFraction,
                fractionText: '${s.progressDone}/${s.progressTotal}',
              ),
              const Spacer(),
              _CompletedPlayArea(
                nextLabel: s.nextLevelLabel,
                onPlay: () => startPlayFlow(context, ref),
                onBonus: () => showComingSoon(context, 'Bonus Gift'),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletedPlayArea extends StatelessWidget {
  const _CompletedPlayArea({
    required this.nextLabel,
    required this.onPlay,
    required this.onBonus,
  });

  final String nextLabel;
  final VoidCallback onPlay;
  final VoidCallback onBonus;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizing.playAreaHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          LilyPadButton(
            size: 180,
            rotationDegrees: 20,
            palette: LilyPadPalette.green,
            semanticLabel: 'Play $nextLabel',
            onPressed: onPlay,
            content: _PlayContent(label: nextLabel),
          ),
          Positioned(
            right: 4,
            top: 8,
            child: LilyPadButton(
              size: 104,
              rotationDegrees: -15,
              palette: LilyPadPalette.teal,
              idle: IdleMotion.bob,
              semanticLabel: 'Bonus Gift',
              onPressed: onBonus,
              content: const _SecondaryContent(
                icon: Icons.local_movies,
                label: 'Bonus Gift',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayContent extends StatelessWidget {
  const _PlayContent({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.play_arrow_rounded,
            size: 56, color: AppColors.playTriangle),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.padLabel,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SecondaryContent extends StatelessWidget {
  const _SecondaryContent({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 28, color: AppColors.padLabel),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.padLabel,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
