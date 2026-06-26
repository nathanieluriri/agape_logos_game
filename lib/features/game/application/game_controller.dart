import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../player/application/player_controller.dart';
import '../../puzzles/application/puzzle_providers.dart';
import '../../puzzles/domain/puzzle.dart';
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
    final isAnswer =
        s.puzzle.answers.any((a) => a.word.toUpperCase() == word);
    if (isAnswer && !s.found.contains(word)) {
      final combo = s.combo + 1;
      state = s.copyWith(
        found: {...s.found, word},
        combo: combo,
        score: s.score + word.length * combo,
        selection: const [],
      );
    } else if (isAnswer) {
      state = s.copyWith(selection: const []); // duplicate
    } else {
      state = s.copyWith(selection: const [], combo: 0); // invalid
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
    final completedAt = DateTime.now().millisecondsSinceEpoch;
    await ref
        .read(puzzleControllerProvider)
        .recordResult(s.puzzle.letterKey, s.score, completedAt);
    ref
        .read(playerStateProvider.notifier)
        .completeLevel(coinsAwarded: _coinsFor(s.score));
  }
}

final gameSessionProvider =
    NotifierProvider<GameController, GameSession?>(GameController.new);
