import 'package:agape_logos_game/core/haptics/haptic_providers.dart';
import 'package:agape_logos_game/core/haptics/haptic_service.dart';
import 'package:agape_logos_game/core/storage/app_database.dart';
import 'package:agape_logos_game/core/storage/storage_providers.dart';
import 'package:agape_logos_game/features/game/application/game_controller.dart';
import 'package:agape_logos_game/features/puzzles/domain/puzzle.dart';
import 'package:agape_logos_game/features/tutorial/application/tutorial_controller.dart';
import 'package:agape_logos_game/features/tutorial/application/tutorial_state.dart';
import 'package:drift/native.dart';
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

const _otherPuzzle = Puzzle(
  tier: 'easy', rackSize: 2, letters: ['O', 'N'], letterKey: 'NO',
  anchor: 'ON', answerCount: 2,
  answers: [
    PuzzleAnswer(word: 'ON', length: 2, definition: null),
    PuzzleAnswer(word: 'NO', length: 2, definition: null),
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

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      hapticServiceProvider.overrideWithValue(_NoopHaptics()),
    ]);
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  /// Activates the tutorial listeners, loads a session, and lets the
  /// settings row arrive (which triggers the auto-start check).
  ///
  /// A durable [container.listen] is what keeps the tutorial notifier (and,
  /// through it, the settings stream it watches) subscribed: a bare
  /// `container.read` never drives a Riverpod `StreamProvider` to emit, so the
  /// settings row would never arrive and the auto-start check would never run.
  Future<void> pumpToStart() async {
    container.listen(tutorialProvider, (_, __) {});
    container.read(gameSessionProvider.notifier).load(_puzzle);
    await pumpEventQueue();
  }

  /// Traces [word] on the wheel exactly like a player drag would.
  void trace(String word) {
    final game = container.read(gameSessionProvider.notifier);
    final session = container.read(gameSessionProvider)!;
    for (final slot in slotsForWord(session.wheelLetters, word)!) {
      game.touchLetter(slot);
    }
    game.endSelection();
  }

  test('starts on a fresh install once a session with nothing found exists',
      () async {
    await pumpToStart();
    final t = container.read(tutorialProvider)!;
    // Targets follow the session order: shortest first, then alphabetical.
    expect(t.targetWords, ['FI', 'IF']);
    expect(t.stepIndex, 0);
    expect(t.phase, TutorialPhase.trace);
  });

  test('does not start when the tutorial was already seen', () async {
    await db.gameSettingsDao.setTutorialSeen(true);
    await pumpToStart();
    expect(container.read(tutorialProvider), isNull);
  });

  test('advances to the next unfound target when the prompted word lands',
      () async {
    await pumpToStart();
    trace('FI');
    final t = container.read(tutorialProvider)!;
    expect(t.stepIndex, 1);
    expect(t.targetWord, 'IF');
    expect(t.phase, TutorialPhase.trace);
  });

  test('a different valid answer keeps prompting the first unfound target',
      () async {
    await pumpToStart();
    trace('IF'); // the second target, out of order
    final t = container.read(tutorialProvider)!;
    expect(t.stepIndex, 0);
    expect(t.targetWord, 'FI');
  });

  test('celebrates and persists seen once every target is found', () async {
    await pumpToStart();
    trace('FI');
    trace('IF');
    expect(container.read(tutorialProvider)!.phase, TutorialPhase.celebrate);
    await pumpEventQueue();
    final row = await db.gameSettingsDao.watch().first;
    expect(row.tutorialSeen, isTrue);

    // The UI acknowledges the celebration; the tutorial fully retires.
    container.read(tutorialProvider.notifier).dismissCelebration();
    expect(container.read(tutorialProvider), isNull);
  });

  test('skip nulls the state and persists seen', () async {
    await pumpToStart();
    container.read(tutorialProvider.notifier).skip();
    expect(container.read(tutorialProvider), isNull);
    await pumpEventQueue();
    final row = await db.gameSettingsDao.watch().first;
    expect(row.tutorialSeen, isTrue);
  });

  test('does not restart within the same run after skip', () async {
    await pumpToStart();
    container.read(tutorialProvider.notifier).skip();
    await pumpEventQueue();
    // A fresh untouched session would qualify, but the dismissal guard holds.
    container.read(gameSessionProvider.notifier).load(_otherPuzzle);
    await pumpEventQueue();
    expect(container.read(tutorialProvider), isNull);
  });
}
