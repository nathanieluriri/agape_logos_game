import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/haptics/haptic_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../../player/application/player_controller.dart';
import '../../profile/application/profile_providers.dart';
import '../../puzzles/application/puzzle_providers.dart';
import '../../puzzles/domain/puzzle.dart';
import '../../puzzles/puzzles_config.dart';
import 'game_session.dart';

/// Free hints granted at the start of each level.
const int kStartingHints = 3;

/// Coins awarded on level completion (flat bonus plus the level score).
int _coinsFor(int score) => 10 + score;

class GameController extends Notifier<GameSession?> {
  @override
  GameSession? build() => null;

  /// Load a fresh session for [puzzle], unless one is already in progress for it.
  void load(Puzzle puzzle) {
    final s = state;
    if (s != null && s.puzzle.letterKey == puzzle.letterKey && !s.isComplete) {
      return;
    }
    state = GameSession.initial(puzzle: puzzle, hintsLeft: kStartingHints);
  }

  void touchLetter(int slot) {
    final s = state;
    if (s == null || s.isComplete) return;
    if (slot < 0 || slot >= s.wheelLetters.length) return;
    if (s.selection.contains(slot)) return;
    state = s.copyWith(selection: [...s.selection, slot]);
  }

  void endSelection() {
    final s = state;
    if (s == null || s.selection.isEmpty) return;
    final word = s.formedWord;
    final isAnswer = s.puzzle.answers.any((a) => a.word.toUpperCase() == word);
    if (isAnswer && !s.found.contains(word)) {
      final combo = s.combo + 1;
      state = s.copyWith(
        found: {...s.found, word},
        combo: combo,
        score: s.score + word.length * combo,
        selection: const [],
      );
      // Escalate the feel with the streak: a first solid landing, a building
      // streak, then a full celebration once the combo is really rolling.
      final haptics = ref.read(hapticServiceProvider);
      if (combo >= 4) {
        haptics.successPattern();
      } else if (combo >= 2) {
        haptics.streakImpact();
      } else {
        haptics.heavyImpact();
      }
    } else if (isAnswer) {
      // Already found: keep the streak, but acknowledge the trace with a tick.
      state = s.copyWith(selection: const []);
      ref.read(hapticServiceProvider).selectionClick();
    } else {
      // Invalid word: the streak is broken. Reset the combo and fire the
      // distinct error buzz so the lost streak is felt, not silent.
      state = s.copyWith(selection: const [], combo: 0);
      ref.read(hapticServiceProvider).mistakeImpact();
    }
  }

  void shuffle() {
    final s = state;
    if (s == null) return;
    state = s.copyWith(
      rackOrder: [...s.rackOrder]..shuffle(),
      selection: const [],
    );
  }

  void useHint() {
    final s = state;
    if (s == null || s.hintsLeft <= 0) return;
    final unfound = s.targets
        .where((a) => !s.found.contains(a.word.toUpperCase()))
        .toList();
    if (unfound.isEmpty) return;
    final word = unfound.first.word.toUpperCase();
    final revealed = s.revealed[word] ?? 0;
    if (revealed >= word.length) return;
    state = s.copyWith(
      revealed: {...s.revealed, word: revealed + 1},
      hintsLeft: s.hintsLeft - 1,
    );
  }

  /// Record the finished level through C1 and advance player progression.
  /// Awaited by the page before navigating, so the next puzzle is ready on return.
  Future<void> commitWin() async {
    final s = state;
    if (s == null || !s.isComplete) return;
    // Celebrate the level win with the full success burst.
    ref.read(hapticServiceProvider).successPattern();
    final completedAt = DateTime.now().millisecondsSinceEpoch;
    final String puzzleId = s.puzzle.letterKey;

    // The level being played is the backend next-level (highestLevel + 1); all
    // of it is derived from the profile. Progress is real: words found over the
    // puzzle's total answers (answerCount comes from the backend puzzle).
    final int completedLevel = ref.read(nextLevelProvider);
    final int totalWords = s.puzzle.answerCount;
    final int wordsFound = s.found.length;

    await ref
        .read(puzzleControllerProvider)
        .recordResult(puzzleId, s.score, completedAt, level: completedLevel);

    // Optimistic profile bumps so the coin pill and next-level label update
    // immediately. The server is authoritative (mints coins, applies the level
    // max) when the puzzle result syncs and reconciles on the next GET /me.
    // Starter puzzles are local-only (never synced), so skip them to avoid
    // values the server will later contradict.
    if (!puzzleId.startsWith(kStarterPuzzlePrefix)) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        final repo = ref.read(profileRepositoryProvider);
        await repo.addCoinsLocally(user.uid, _coinsFor(s.score));
        await repo.advanceLevelLocally(user.uid, completedLevel);
      }
    }

    ref
        .read(levelCompletionProvider.notifier)
        .recordCompletion(
          completedLevel: completedLevel,
          wordsFound: wordsFound,
          totalWords: totalWords,
          words: s.targets,
        );
  }
}

final gameSessionProvider = NotifierProvider<GameController, GameSession?>(
  GameController.new,
);
