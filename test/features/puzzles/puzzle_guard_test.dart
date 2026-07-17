import 'package:agape_logos_game/features/puzzles/data/puzzle_guard.dart';
import 'package:agape_logos_game/features/puzzles/domain/puzzle.dart';
import 'package:flutter_test/flutter_test.dart';

Puzzle _puzzle(List<PuzzleAnswer> answers) => Puzzle(
      tier: 'easy',
      rackSize: 4,
      letters: const ['C', 'A', 'T', 'S'],
      letterKey: 'starter-easy-01',
      anchor: 'T',
      answers: answers,
      answerCount: answers.length,
    );

void main() {
  test('keeps a fully defined puzzle untouched', () {
    final puzzle = _puzzle(const [
      PuzzleAnswer(word: 'CAT', length: 3, definition: 'a feline'),
      PuzzleAnswer(word: 'ACT', length: 3, definition: 'a deed'),
      PuzzleAnswer(word: 'CATS', length: 4, definition: 'many cats'),
    ]);
    expect(guardDefinedAnswers(puzzle), same(puzzle));
  });

  test('drops undefined words and recomputes answerCount', () {
    final guarded = guardDefinedAnswers(_puzzle(const [
      PuzzleAnswer(word: 'CAT', length: 3, definition: 'a feline'),
      PuzzleAnswer(word: 'ACT', length: 3, definition: 'a deed'),
      PuzzleAnswer(word: 'CATS', length: 4, definition: null),
    ]));
    expect(guarded, isNotNull);
    expect(guarded!.answers.map((a) => a.word), ['CAT', 'ACT']);
    expect(guarded.answerCount, 2);
  });

  test('treats blank or whitespace definitions as missing', () {
    final guarded = guardDefinedAnswers(_puzzle(const [
      PuzzleAnswer(word: 'CAT', length: 3, definition: 'a feline'),
      PuzzleAnswer(word: 'ACT', length: 3, definition: 'a deed'),
      PuzzleAnswer(word: 'TAC', length: 3, definition: '   '),
    ]));
    expect(guarded!.answers.map((a) => a.word), ['CAT', 'ACT']);
  });

  test('returns null when too few defined words remain', () {
    final guarded = guardDefinedAnswers(_puzzle(const [
      PuzzleAnswer(word: 'CAT', length: 3, definition: 'a feline'),
      PuzzleAnswer(word: 'ACT', length: 3, definition: null),
      PuzzleAnswer(word: 'CATS', length: 4, definition: ''),
    ]));
    expect(guarded, isNull);
  });
}
