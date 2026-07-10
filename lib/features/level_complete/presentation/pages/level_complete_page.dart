// lib/features/level_complete/presentation/pages/level_complete_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/gradients.dart';
import '../../../../core/design/tokens/sizing.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../features/player/application/player_controller.dart';
import '../../../../features/player/application/player_state.dart';
import '../../../../features/profile/application/profile_providers.dart';
import '../../../../shared/widgets/play_pad_cluster.dart';
import '../../../../shared/widgets/pond_background.dart';
import '../../../../shared/widgets/pond_stage.dart';
import '../../../../shared/widgets/pond_top_bar.dart';
import '../../../../shared/widgets/wordmark_logo.dart';
import '../../../game/presentation/widgets/dictionary_sheet.dart';
import '../../../puzzles/domain/puzzle.dart';
import '../widgets/level_progress_bar.dart';

/// The level-complete screen. Thin composition, and safe: it only celebrates
/// when there is a [LevelSummary] to celebrate. Without one (a web reload that
/// restored this route, or a stray navigation), there is nothing to show, so it
/// bounces Home instead of rendering an empty 0/0 bar. The secondary pad is a
/// Dictionary that opens the words from the level just completed.
class LevelCompletePage extends ConsumerWidget {
  const LevelCompletePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(levelCompletionProvider);
    if (summary == null) {
      // Nothing to celebrate: leave for Home after this frame. go() is
      // idempotent, so a duplicate schedule (should build run twice before the
      // route changes) is harmless.
      // PLAN: if a physical device ever shows a double-navigation glitch,
      // promote this to a ConsumerStatefulWidget with a `_redirecting` flag.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/');
      });
      return const _NoSummaryFallback();
    }
    return _LevelCompleteBody(summary: summary);
  }
}

/// A calm, tickerless pond wash painted for the single frame before the redirect
/// (Part A). No bar, no numeral, so the broken 0/0 state can never flash.
class _NoSummaryFallback extends StatelessWidget {
  const _NoSummaryFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(gradient: AppGradients.pond),
      child: SizedBox.expand(),
    );
  }
}

/// The celebration itself, always built with a non-null [summary].
class _LevelCompleteBody extends ConsumerWidget {
  const _LevelCompleteBody({required this.summary});

  final LevelSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(coinsProvider);
    final nextLabel = 'Lv.${ref.watch(nextLevelProvider)}';
    final words = summary.words;
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
                label: summary.completedLabel,
                wordsFound: summary.wordsFound,
                totalWords: summary.totalWords,
              ),
              const Spacer(),
              PlayPadCluster(
                nextLabel: nextLabel,
                // Replace (not push) so Android back from the next level goes
                // straight Home, and the finished level cannot be replayed.
                onPlay: () => context.pushReplacement('/game'),
                secondaryIcon: const Icon(
                  Icons.menu_book_rounded,
                  size: AppSizing.secondaryPadIcon,
                  color: AppColors.padLabel,
                ),
                secondaryLabel: 'Dictionary',
                onSecondary: () => _openDictionary(context, words),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens the reused session dictionary sheet for the just-completed puzzle.
  /// On a win every answer was found, so all words show with their definitions
  /// (found = all words upper-cased; nothing stays masked).
  // PLAN (owner confirmation): this removes the level-complete coin-claim
  // shortcut (the old Bonus Gift). The SAME reward stays claimable from the
  // Home daily-gift disc (RewardGiftButton), so no reward functionality is
  // lost. Confirm with the owner before merge.
  void _openDictionary(BuildContext context, List<PuzzleAnswer> words) {
    showDictionarySheet(
      context,
      targets: words,
      found: {for (final w in words) w.word.toUpperCase()},
      revealed: const {},
    );
  }
}
