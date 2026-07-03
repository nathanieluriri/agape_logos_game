import 'package:agape_logos_game/core/haptics/haptic_providers.dart';
import 'package:agape_logos_game/core/haptics/haptic_service.dart';
import 'package:agape_logos_game/features/auth/application/auth_providers.dart';
import 'package:agape_logos_game/features/game/application/game_controller.dart';
import 'package:agape_logos_game/features/player/application/player_controller.dart';
import 'package:agape_logos_game/features/profile/application/profile_providers.dart';
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

/// Silent haptics so unit tests never touch a platform channel.
class _NoopHaptics implements HapticService {
  @override
  Future<void> init() async {}
  @override
  Future<void> lightImpact() async {}
  @override
  Future<void> mediumImpact() async {}
  @override
  Future<void> heavyImpact() async {}
  @override
  Future<void> gameImpact() async {}
  @override
  Future<void> streakImpact() async {}
  @override
  Future<void> mistakeImpact() async {}
  @override
  Future<void> selectionClick() async {}
  @override
  void setMuted(bool muted) {}
}

class _FakePuzzleController implements PuzzleController {
  String? recordedId;
  int? recordedScore;
  int? recordedLevel;
  @override
  Future<void> recordResult(
    String puzzleId,
    int score,
    int completedAt, {
    int? level,
  }) async {
    recordedId = puzzleId;
    recordedScore = score;
    recordedLevel = level;
  }
  @override
  Future<void> refresh() async {}
}

ProviderContainer _container(_FakePuzzleController fake) {
  final c = ProviderContainer(overrides: [
    puzzleControllerProvider.overrideWithValue(fake),
    // No signed-in user: commitWin's optimistic coin bump is skipped, so the
    // test needs neither Firebase nor a profile repo.
    currentUserProvider.overrideWithValue(null),
    hapticServiceProvider.overrideWithValue(_NoopHaptics()),
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

  test('completing the puzzle commits the result with the level and records '
      'a real completion summary', () async {
    final fake = _FakePuzzleController();
    final c = _container(fake);
    final g = c.read(gameSessionProvider.notifier)..load(_puzzle);
    // Signed out -> backend highestLevel defaults to 0, so the level being
    // played (and completed) is 1.
    final startLevel = c.read(nextLevelProvider);
    expect(startLevel, 1);

    g.touchLetter(0); g.touchLetter(1); g.endSelection(); // IF
    g.touchLetter(1); g.touchLetter(0); g.endSelection(); // FI -> complete
    expect(c.read(gameSessionProvider)!.isComplete, isTrue);

    await g.commitWin();
    expect(fake.recordedId, 'FI');
    expect(fake.recordedScore, isNonNegative);
    // The completed level is threaded to the backend.
    expect(fake.recordedLevel, startLevel);

    // Progress summary is real: both answers found out of the puzzle's two.
    final summary = c.read(levelCompletionProvider)!;
    expect(summary.completedLevel, startLevel);
    expect(summary.wordsFound, 2);
    expect(summary.totalWords, 2);
    expect(summary.progressFraction, 1.0);
  });
}
