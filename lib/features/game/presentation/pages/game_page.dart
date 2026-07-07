import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/pond_background.dart';
import '../../../../shared/widgets/pond_loader.dart';
import '../../../profile/application/profile_providers.dart';
import '../../../puzzles/application/puzzle_providers.dart';
import '../../../tutorial/presentation/widgets/tutorial_overlay.dart';
import '../../application/game_controller.dart';
import '../../application/game_session.dart';
import '../widgets/combo_banner.dart';
import '../widgets/dictionary_sheet.dart';
import '../widgets/empty_pond_notice.dart';
import '../widgets/formed_word_pill.dart';
import '../widgets/game_top_bar.dart';
import '../widgets/letter_wheel.dart';
import '../widgets/streak_confetti.dart';
import '../widgets/wheel_action_button.dart';
import '../widgets/word_board.dart';

class GamePage extends ConsumerStatefulWidget {
  const GamePage({super.key});

  @override
  ConsumerState<GamePage> createState() => _GamePageState();
}

class _GamePageState extends ConsumerState<GamePage> {
  bool _navigating = false;

  // Anchors for the tutorial overlay's spotlight cutouts.
  final _wheelKey = GlobalKey();
  final _boardKey = GlobalKey();

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
    // Replace this route rather than stacking level-complete on top of it, so
    // the gameplay stack never grows past a single screen above Home. A fresh
    // GamePage (opened from level-complete's Play) loads the next puzzle in its
    // own initState, so there is nothing to reload here.
    context.pushReplacement('/level-complete');
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
    final puzzleAsync = ref.watch(currentPuzzleProvider);
    final coins = ref.watch(coinsProvider);
    final level = ref.watch(nextLevelProvider);
    final controller = ref.read(gameSessionProvider.notifier);

    // The stream resolved to "no unplayed puzzles" and nothing is loading:
    // show a retry notice instead of spinning forever.
    final pondEmpty = session == null &&
        !puzzleAsync.isLoading &&
        puzzleAsync.asData?.value == null;

    return Scaffold(
      body: PondBackground(
        child: SafeArea(
          child: session == null
              ? (pondEmpty
                  ? EmptyPondNotice(
                      onRetry: () =>
                          ref.read(puzzleControllerProvider).refresh(),
                    )
                  : const Center(
                      child: PondLoader(
                        label: 'Loading puzzle',
                      ),
                    ))
              : Stack(
                  children: [
                    Column(
                      children: [
                        GameTopBar(
                          level: level,
                          coins: coins,
                          onBack: () => context.pop(),
                          onDictionary: () => showDictionarySheet(
                            context,
                            targets: session.targets,
                            found: session.found,
                            revealed: session.revealed,
                          ),
                        ),
                        Expanded(
                          child: WordBoard(
                            key: _boardKey,
                            targets: session.targets,
                            found: session.found,
                            revealed: session.revealed,
                            center: true,
                          ),
                        ),
                        // Confetti bursts from behind the capsule on each new
                        // streak; the Stack does not clip, so bits fly free.
                        Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            Positioned.fill(
                              child: StreakConfetti(combo: session.combo),
                            ),
                            ComboBanner(
                                praise: session.praise, combo: session.combo),
                          ],
                        ),
                        FormedWordPill(word: session.formedWord),
                        const SizedBox(height: AppSpacing.md),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.lg,
                          ),
                          // FittedBox scales the fixed-width cluster down on
                          // narrow phones so the wheel + flanking buttons
                          // never overflow.
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
                                  key: _wheelKey,
                                  letters: session.wheelLetters,
                                  selected: session.selection,
                                  ids: session.rackOrder,
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
                    // Built whenever a session exists (it decides its own
                    // visibility): watching tutorialProvider from here is
                    // what wires the tutorial controller's listeners.
                    Positioned.fill(
                      child: TutorialOverlay(
                        wheelKey: _wheelKey,
                        boardKey: _boardKey,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
