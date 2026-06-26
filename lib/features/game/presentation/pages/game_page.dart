import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/pond_background.dart';
import '../../../player/application/player_controller.dart';
import '../../../puzzles/application/puzzle_providers.dart';
import '../../application/game_controller.dart';
import '../../application/game_session.dart';
import '../widgets/combo_banner.dart';
import '../widgets/formed_word_pill.dart';
import '../widgets/game_top_bar.dart';
import '../widgets/letter_wheel.dart';
import '../widgets/wheel_action_button.dart';
import '../widgets/word_board.dart';

class GamePage extends ConsumerStatefulWidget {
  const GamePage({super.key});

  @override
  ConsumerState<GamePage> createState() => _GamePageState();
}

class _GamePageState extends ConsumerState<GamePage> {
  bool _navigating = false;

  void _loadFromCurrent() {
    final puzzle = ref.read(currentPuzzleProvider).asData?.value;
    if (puzzle != null) {
      ref.read(gameSessionProvider.notifier).load(puzzle);
    } else {
      ref.read(puzzleControllerProvider).refresh();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadFromCurrent();
    });
  }

  Future<void> _onComplete() async {
    if (_navigating) return;
    _navigating = true;
    await ref.read(gameSessionProvider.notifier).commitWin();
    if (!mounted) return;
    await context.push('/level-complete');
    if (!mounted) return;
    _navigating = false;
    _loadFromCurrent();
  }

  @override
  Widget build(BuildContext context) {
    // Load when a puzzle becomes available.
    ref.listen(currentPuzzleProvider, (_, next) {
      if (next.asData?.value != null) _loadFromCurrent();
    });
    // Navigate once when the level is complete.
    ref.listen<GameSession?>(gameSessionProvider, (prev, next) {
      final justCompleted =
          next != null && next.isComplete && (prev == null || !prev.isComplete);
      if (justCompleted) _onComplete();
    });

    final session = ref.watch(gameSessionProvider);
    final coins = ref.watch(playerStateProvider.select((s) => s.coins));
    final level = ref.watch(playerStateProvider.select((s) => s.currentLevel));
    final controller = ref.read(gameSessionProvider.notifier);

    return Scaffold(
      body: PondBackground(
        child: SafeArea(
          child: session == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    GameTopBar(
                      level: level,
                      coins: coins,
                      onBack: () => context.pop(),
                      onDictionary: () =>
                          ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Dictionary coming soon')),
                      ),
                    ),
                    Expanded(
                      child: WordBoard(
                        targets: session.targets,
                        found: session.found,
                        revealed: session.revealed,
                      ),
                    ),
                    ComboBanner(praise: session.praise, combo: session.combo),
                    FormedWordPill(word: session.formedWord),
                    const SizedBox(height: AppSpacing.md),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.lg,
                      ),
                      // FittedBox scales the fixed-width cluster down on narrow
                      // phones so the wheel + flanking buttons never overflow.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            WheelActionButton(
                              icon: Icons.shuffle,
                              semanticLabel: 'Shuffle',
                              onTap: controller.shuffle,
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            LetterWheel(
                              letters: session.wheelLetters,
                              selected: session.selection,
                              onTouch: controller.touchLetter,
                              onEnd: controller.endSelection,
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            WheelActionButton(
                              icon: Icons.lightbulb_outline,
                              semanticLabel: 'Hint',
                              onTap: controller.useHint,
                              badge: session.hintsLeft,
                              enabled: session.hintsLeft > 0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
