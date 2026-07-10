import 'package:agape_logos_game/features/player/application/player_controller.dart';
import 'package:agape_logos_game/features/puzzles/domain/puzzle.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _words = [
  PuzzleAnswer(word: 'CAB', length: 3, definition: 'a taxi'),
  PuzzleAnswer(word: 'ABC', length: 3, definition: null),
];

void main() {
  test('recordCompletion carries the completed puzzle words into the summary', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(levelCompletionProvider.notifier).recordCompletion(
          completedLevel: 3,
          wordsFound: 2,
          totalWords: 2,
          words: _words,
        );

    final summary = container.read(levelCompletionProvider);
    expect(summary?.completedLevel, 3);
    expect(summary?.words.map((w) => w.word), ['CAB', 'ABC']);
    expect(summary?.completedLabel, 'Level 3 Completed!');
    expect(summary?.fractionText, '2/2');
  });
}
