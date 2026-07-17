import 'package:agape_logos_game/core/haptics/haptic_providers.dart';
import 'package:agape_logos_game/core/haptics/haptic_service.dart';
import 'package:agape_logos_game/core/storage/app_database.dart';
import 'package:agape_logos_game/core/storage/storage_providers.dart';
import 'package:agape_logos_game/features/auth/application/auth_providers.dart';
import 'package:agape_logos_game/features/game/presentation/pages/game_page.dart';
import 'package:agape_logos_game/features/profile/application/profile_providers.dart';
import 'package:agape_logos_game/features/puzzles/application/puzzle_providers.dart';
import 'package:agape_logos_game/features/puzzles/domain/puzzle.dart';
import 'package:agape_logos_game/features/settings/application/settings_providers.dart';
import 'package:agape_logos_game/features/tutorial/presentation/widgets/tutorial_message_pill.dart';
import 'package:agape_logos_game/game/ambient/ambient_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _puzzle = Puzzle(
  tier: 'easy', rackSize: 3, letters: ['F', 'I', 'T'], letterKey: 'FIT',
  anchor: 'FIT', answerCount: 2,
  answers: [
    PuzzleAnswer(word: 'IF', length: 2, definition: null),
    PuzzleAnswer(word: 'FIT', length: 3, definition: null),
  ],
);

class _FakePuzzleController implements PuzzleController {
  @override
  Future<void> recordResult(
    String puzzleId,
    int score,
    int completedAt, {
    int? level,
  }) async {}
  @override
  Future<void> refresh() async {}
  @override
  Future<void> recover() async {}
}

/// Silent haptics so widget tests never touch a platform channel.
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
  Future<void> successPattern() async {}
  @override
  Future<void> tickImpact() async {}
  @override
  void setMuted(bool muted) {}
}

GoRouter _router() => GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const GamePage()),
      GoRoute(
        path: '/level-complete',
        builder: (_, __) => const Scaffold(body: Text('Level complete')),
      ),
    ]);

/// Settings with tutorialSeen false so the tutorial auto-starts. Injected as a
/// static stream rather than the live Drift stream: driving the widget off the
/// live stream deadlocks under fake-async and leaves the query-cleanup timer
/// pending past teardown. The real DB still backs writes (skip persists through
/// [settingsDaoProvider]); we read it back with a one-shot query in the test.
const _settingsRow = GameSettingsRow(
  id: 0,
  soundEffects: true,
  music: true,
  notifications: true,
  haptics: true,
  tutorialSeen: false,
  powerupTutorialSeen: true,
);

/// GamePage with the real game session and a static settings stream. Reduced
/// motion keeps the tutorial hand static so pumps stay bounded.
Widget _app(AppDatabase db) => ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        settingsProvider.overrideWith((ref) => Stream.value(_settingsRow)),
        hapticServiceProvider.overrideWithValue(_NoopHaptics()),
        currentPuzzleProvider.overrideWith((ref) => Stream.value(_puzzle)),
        puzzleControllerProvider.overrideWithValue(_FakePuzzleController()),
        ambientEnabledProvider.overrideWithValue(false),
        coinsProvider.overrideWithValue(0),
        nextLevelProvider.overrideWithValue(1),
        currentUserProvider.overrideWithValue(null),
      ],
      child: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp.router(routerConfig: _router()),
      ),
    );

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() async => db.close());

  /// Pumps until the puzzle loads, the settings row arrives, the tutorial
  /// starts, and the overlay resolves the wheel/board rects. Fixed pumps,
  /// never pumpAndSettle: the overlay owns a repeating controller in real
  /// runs, and reduced motion still leaves async DB emissions to drain.
  Future<void> pumpToTutorial(WidgetTester tester) async {
    await tester.pumpWidget(_app(db));
    await tester.pump(); // puzzle stream emits
    await tester.pump(); // post-frame load -> session
    await tester.pump(const Duration(milliseconds: 50)); // settings row lands
    await tester.pump(const Duration(milliseconds: 50)); // rects resolve
  }

  testWidgets('shows the coach pill prompting the first target word',
      (tester) async {
    await pumpToTutorial(tester);

    expect(find.byType(TutorialMessagePill), findsOneWidget);
    // First target is the shortest answer: IF.
    expect(
      find.text('Drag across the letters to spell IF.', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('Skip dismisses the overlay and persists tutorialSeen',
      (tester) async {
    await pumpToTutorial(tester);

    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(TutorialMessagePill), findsNothing);
    expect(find.text('Skip'), findsNothing);
    // One-shot read (not watch): a live Drift stream would leave its cleanup
    // timer pending past the end of the test.
    final row = await (db.select(db.gameSettings)
          ..where((t) => t.id.equals(0)))
        .getSingle();
    expect(row.tutorialSeen, isTrue);
  });
}
