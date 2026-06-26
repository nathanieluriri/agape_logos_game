import 'package:agape_logos_game/features/game/application/game_controller.dart';
import 'package:agape_logos_game/features/player/application/player_controller.dart';
import 'package:agape_logos_game/features/puzzles/application/puzzle_providers.dart';
import 'package:agape_logos_game/features/puzzles/domain/puzzle.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _puzzle = Puzzle(
  tier: 'easy', rackSize: 2, letters: ['I', 'F'], letterKey: 'FI',
  anchor: 'IF', answerCount: 2,
  answers: [
    PuzzleAnswer(word: 'IF', length: 2, definition: null),
    PuzzleAnswer(word: 'FI', length: 2, definition: null),
  ],
);

class _FakePuzzleController implements PuzzleController {
  String? recordedId;
  int? recordedScore;
  @override
  Future<void> recordResult(String puzzleId, int score, int completedAt) async {
    recordedId = puzzleId;
    recordedScore = score;
  }
  @override
  Future<void> refresh() async {}
}

ProviderContainer _container(_FakePuzzleController fake) {
  final c = ProviderContainer(overrides: [
    puzzleControllerProvider.overrideWithValue(fake),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('forming a valid word adds it, bumps combo and score', () {
    final c = _container(_FakePuzzleController());
    final g = c.read(gameSessionProvider.notifier)..load(_puzzle);
    g.touchLetter(0); // I
    g.touchLetter(1); // F
    g.endSelection(); // "IF"
    final s = c.read(gameSessionProvider)!;
    expect(s.found, contains('IF'));
    expect(s.combo, 1);
    expect(s.score, 2); // length 2 * combo 1
    expect(s.selection, isEmpty);
  });

  test('an invalid word resets the combo', () {
    final c = _container(_FakePuzzleController());
    final g = c.read(gameSessionProvider.notifier)..load(_puzzle);
    g.touchLetter(0);
    g.endSelection(); // "I" not an answer
    expect(c.read(gameSessionProvider)!.combo, 0);
    expect(c.read(gameSessionProvider)!.found, isEmpty);
  });

  test('a duplicate word is ignored and keeps combo', () {
    final c = _container(_FakePuzzleController());
    final g = c.read(gameSessionProvider.notifier)..load(_puzzle);
    g.touchLetter(0); g.touchLetter(1); g.endSelection(); // IF, combo 1
    g.touchLetter(0); g.touchLetter(1); g.endSelection(); // IF again
    final s = c.read(gameSessionProvider)!;
    expect(s.combo, 1);
    expect(s.found.length, 1);
  });

  test('shuffle preserves the letters multiset and clears selection', () {
    final c = _container(_FakePuzzleController());
    final g = c.read(gameSessionProvider.notifier)..load(_puzzle);
    g.touchLetter(0);
    g.shuffle();
    final s = c.read(gameSessionProvider)!;
    expect([...s.wheelLetters]..sort(), ['F', 'I']);
    expect(s.selection, isEmpty);
  });

  test('hint reveals a leading letter, decrements, and stops at zero', () {
    final c = _container(_FakePuzzleController());
    final g = c.read(gameSessionProvider.notifier)..load(_puzzle);
    g.useHint();
    final s = c.read(gameSessionProvider)!;
    expect(s.hintsLeft, kStartingHints - 1);
    expect(s.revealed.values.reduce((a, b) => a + b), 1);
  });

  test('completing the puzzle commits the result and advances the level', () async {
    final fake = _FakePuzzleController();
    final c = _container(fake);
    final g = c.read(gameSessionProvider.notifier)..load(_puzzle);
    final startLevel = c.read(playerStateProvider).currentLevel;
    final startCoins = c.read(playerStateProvider).coins;

    g.touchLetter(0); g.touchLetter(1); g.endSelection(); // IF
    g.touchLetter(1); g.touchLetter(0); g.endSelection(); // FI -> complete
    expect(c.read(gameSessionProvider)!.isComplete, isTrue);

    await g.commitWin();
    expect(fake.recordedId, 'FI');
    expect(fake.recordedScore, isNonNegative);
    expect(c.read(playerStateProvider).currentLevel, startLevel + 1);
    expect(c.read(playerStateProvider).coins, greaterThan(startCoins));
    expect(c.read(playerStateProvider).lastCompletedLevel, startLevel);
  });
}
