import 'package:agape_logos_game/features/game/application/game_session.dart';
import 'package:agape_logos_game/features/puzzles/domain/puzzle.dart';
import 'package:flutter_test/flutter_test.dart';

const _puzzle = Puzzle(
  tier: 'easy', rackSize: 3, letters: ['T', 'O', 'P'], letterKey: 'OPT',
  anchor: 'TOP', answerCount: 3,
  answers: [
    PuzzleAnswer(word: 'TOP', length: 3, definition: null),
    PuzzleAnswer(word: 'TO', length: 2, definition: null),
    PuzzleAnswer(word: 'OPT', length: 3, definition: null),
  ],
);

void main() {
  test('initial session has identity rackOrder and full hints', () {
    final s = GameSession.initial(puzzle: _puzzle, hintsLeft: 3);
    expect(s.rackOrder, [0, 1, 2]);
    expect(s.wheelLetters, ['T', 'O', 'P']);
    expect(s.selection, isEmpty);
    expect(s.hintsLeft, 3);
    expect(s.isComplete, isFalse);
  });

  test('targets are sorted by length then word', () {
    final s = GameSession.initial(puzzle: _puzzle, hintsLeft: 3);
    expect(s.targets.map((a) => a.word).toList(), ['TO', 'OPT', 'TOP']);
  });

  test('formedWord reads the selected wheel slots in order', () {
    final s = GameSession.initial(puzzle: _puzzle, hintsLeft: 3)
        .copyWith(selection: [0, 1]);
    expect(s.formedWord, 'TO');
  });

  test('isComplete is true only when every answer is found', () {
    final s = GameSession.initial(puzzle: _puzzle, hintsLeft: 3);
    expect(s.copyWith(found: {'TOP', 'TO'}).isComplete, isFalse);
    expect(s.copyWith(found: {'TOP', 'TO', 'OPT'}).isComplete, isTrue);
  });

  test('praiseForCombo escalates', () {
    expect(praiseForCombo(1), isNull);
    expect(praiseForCombo(2), 'Good!');
    expect(praiseForCombo(3), 'Great!');
    expect(praiseForCombo(5), 'Expert!');
  });
}
