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
import '../../../../core/design/tokens/colors.dart';

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
      _recover();
    }
  }

  Future<void> _recover() async {
    await ref.read(puzzleControllerProvider).recover();
    if (!mounted) return;
    // Re-subscribe so watchCurrentPuzzle re-runs its decrypt/guard with the
    // (now refreshed) answer key, even when recover wrote no new rows.
    ref.invalidate(currentPuzzleProvider);
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

    // Only the session's existence is watched here: every field is watched by
    // the leaf that consumes it, so a drag (which mutates `selection`) does not
    // rebuild the whole page.
    final hasSession = ref.watch(gameSessionProvider.select((s) => s != null));
    final puzzleAsync = ref.watch(currentPuzzleProvider);

    // The stream resolved to "no unplayed puzzles" and nothing is loading:
    // show a retry notice instead of spinning forever.
    final pondEmpty =
        !hasSession &&
        !puzzleAsync.isLoading &&
        puzzleAsync.asData?.value == null;

    return Scaffold(
      backgroundColor: AppColors.transparent,
      body: PondBackground(
        child: SafeArea(
          child: !hasSession
              ? (pondEmpty
                    ? EmptyPondNotice(onRetry: _recover)
                    : const Center(child: PondLoader(label: 'Loading puzzle')))
              : Stack(
                  children: [
                    Column(
                      children: [
                        const _TopBarSlot(),
                        Expanded(child: _BoardSlot(boardKey: _boardKey)),
                        const _ComboSlot(),
                        const _FormedWordSlot(),
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
                                const _ShuffleButton(),
                                const SizedBox(width: AppSpacing.lg),
                                _WheelSlot(wheelKey: _wheelKey),
                                const SizedBox(width: AppSpacing.lg),
                                const _HintButton(),
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

/// The session, read without subscribing. Every slot below is already gated on
/// the one field it watches, so the derived getters (which allocate a fresh
/// list per call and therefore can never be compared by `select`) are pulled
/// from here instead of being selected.
GameSession _session(WidgetRef ref) => ref.read(gameSessionProvider)!;

class _TopBarSlot extends ConsumerWidget {
  const _TopBarSlot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(coinsProvider);
    final level = ref.watch(nextLevelProvider);
    return GameTopBar(
      level: level,
      coins: coins,
      onBack: () => context.pop(),
      onDictionary: () {
        final session = _session(ref);
        showDictionarySheet(
          context,
          targets: session.targets,
          found: session.found,
          revealed: session.revealed,
        );
      },
    );
  }
}

class _BoardSlot extends ConsumerWidget {
  const _BoardSlot({required this.boardKey});

  final GlobalKey boardKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(gameSessionProvider.select((s) => s?.puzzle));
    ref.watch(gameSessionProvider.select((s) => s?.found));
    ref.watch(gameSessionProvider.select((s) => s?.revealed));
    final session = _session(ref);
    return WordBoard(
      key: boardKey,
      targets: session.targets,
      found: session.found,
      revealed: session.revealed,
      center: true,
    );
  }
}

class _ComboSlot extends ConsumerWidget {
  const _ComboSlot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final combo = ref.watch(gameSessionProvider.select((s) => s?.combo ?? 0));
    // Confetti bursts from behind the capsule on each new streak; the Stack
    // does not clip, so bits fly free.
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Positioned.fill(child: StreakConfetti(combo: combo)),
        ComboBanner(praise: praiseForCombo(combo), combo: combo),
      ],
    );
  }
}

class _FormedWordSlot extends ConsumerWidget {
  const _FormedWordSlot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final word = ref.watch(
      gameSessionProvider.select((s) => s?.formedWord ?? ''),
    );
    return FormedWordPill(word: word);
  }
}

class _WheelSlot extends ConsumerWidget {
  const _WheelSlot({required this.wheelKey});

  final GlobalKey wheelKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(gameSessionProvider.select((s) => s?.puzzle));
    final rackOrder =
        ref.watch(gameSessionProvider.select((s) => s?.rackOrder)) ??
        const <int>[];
    final selection =
        ref.watch(gameSessionProvider.select((s) => s?.selection)) ??
        const <int>[];
    final controller = ref.read(gameSessionProvider.notifier);
    return LetterWheel(
      key: wheelKey,
      letters: _session(ref).wheelLetters,
      selected: selection,
      ids: rackOrder,
      onTouch: controller.touchLetter,
      onEnd: controller.endSelection,
    );
  }
}

class _ShuffleButton extends ConsumerWidget {
  const _ShuffleButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) => WheelActionButton(
    icon: Icons.shuffle,
    semanticLabel: 'Shuffle',
    onTap: ref.read(gameSessionProvider.notifier).shuffle,
  );
}

class _HintButton extends ConsumerWidget {
  const _HintButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hintsLeft = ref.watch(
      gameSessionProvider.select((s) => s?.hintsLeft ?? 0),
    );
    return WheelActionButton(
      icon: Icons.lightbulb_outline,
      semanticLabel: 'Hint',
      onTap: ref.read(gameSessionProvider.notifier).useHint,
      badge: hintsLeft,
      enabled: hintsLeft > 0,
    );
  }
}
