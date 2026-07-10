import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../puzzles/domain/puzzle.dart';
import 'player_state.dart';

/// Holds the most recent [LevelSummary] for the level-complete screen. Written
/// by the game controller on a win from real puzzle data; null until then.
/// Level numbering and the wallet live on the backend profile (see
/// `nextLevelProvider` / `coinsProvider`), not here.
class PlayerController extends Notifier<LevelSummary?> {
  @override
  LevelSummary? build() => null;

  /// Record the just-completed level for the summary screen.
  void recordCompletion({
    required int completedLevel,
    required int wordsFound,
    required int totalWords,
    required List<PuzzleAnswer> words,
  }) {
    state = LevelSummary(
      completedLevel: completedLevel,
      wordsFound: wordsFound,
      totalWords: totalWords,
      words: words,
    );
  }
}

final levelCompletionProvider =
    NotifierProvider<PlayerController, LevelSummary?>(PlayerController.new);
