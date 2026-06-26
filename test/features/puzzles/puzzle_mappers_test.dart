import 'package:agape_logos_game/core/storage/app_database.dart';
import 'package:agape_logos_game/features/puzzles/data/puzzle_mappers.dart';
import 'package:agape_logos_game/features/puzzles/domain/puzzle.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

void main() {
  const puzzle = Puzzle(
    tier: 'easy',
    rackSize: 3,
    letters: ['W', 'N', 'O'],
    letterKey: 'NOW',
    anchor: 'NOW',
    answers: [
      PuzzleAnswer(word: 'NO', length: 2, definition: 'not any'),
      PuzzleAnswer(word: 'NOW', length: 3, definition: null),
    ],
    answerCount: 2,
  );

  test('Puzzle.fromJson tolerates extra server fields', () {
    final p = Puzzle.fromJson({
      'tier': 'easy', 'rackSize': 3, 'letters': ['W', 'N', 'O'],
      'letterKey': 'NOW', 'anchor': 'NOW', 'answerCount': 2,
      'answers': [
        {'word': 'NO', 'length': 2, 'definition': 'not any'},
        {'word': 'NOW', 'length': 3, 'definition': null},
      ],
      'genVersion': 1, 'generatedAt': 123, // extra, ignored
    });
    expect(p.letterKey, 'NOW');
    expect(p.answers.first.word, 'NO');
  });

  test('tierRankOf maps tiers', () {
    expect([tierRankOf('easy'), tierRankOf('medium'), tierRankOf('hard'), tierRankOf('expert')], [0, 1, 2, 3]);
  });

  test('puzzleToCompanion then puzzleFromRow round-trips', () {
    final companion = puzzleToCompanion(puzzle, orderIndex: 7, assignedAt: 42);
    expect(companion.tierRank, const Value(0));
    expect(companion.orderIndex, const Value(7));
    final row = CachedPuzzleRow(
      puzzleId: companion.puzzleId.value,
      tier: companion.tier.value,
      tierRank: companion.tierRank.value,
      rackSize: companion.rackSize.value,
      lettersJson: companion.lettersJson.value,
      anchor: companion.anchor.value,
      answersJson: companion.answersJson.value,
      answerCount: companion.answerCount.value,
      orderIndex: companion.orderIndex.value,
      completed: false,
      assignedAt: companion.assignedAt.value,
    );
    final back = puzzleFromRow(row);
    expect(back, puzzle);
  });
}
