import 'package:agape_logos_game/features/auth/application/auth_providers.dart';
import 'package:agape_logos_game/features/game/application/game_controller.dart';
import 'package:agape_logos_game/features/game/presentation/pages/game_page.dart';
import 'package:agape_logos_game/features/profile/application/profile_providers.dart';
import 'package:agape_logos_game/features/puzzles/application/puzzle_providers.dart';
import 'package:agape_logos_game/features/puzzles/domain/puzzle.dart';
import 'package:agape_logos_game/game/ambient/ambient_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _puzzle = Puzzle(
  tier: 'easy', rackSize: 2, letters: ['I', 'F'], letterKey: 'FI',
  anchor: 'IF', answerCount: 1,
  answers: [PuzzleAnswer(word: 'IF', length: 2, definition: null)],
);

class _FakePuzzleController implements PuzzleController {
  bool recorded = false;
  @override
  Future<void> recordResult(
    String puzzleId,
    int score,
    int completedAt, {
    int? level,
  }) async {
    recorded = true;
  }
  @override
  Future<void> refresh() async {}
}

// A minimal router so GamePage's context.push('/level-complete') works in tests.
GoRouter _router() => GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const GamePage()),
      GoRoute(
        path: '/level-complete',
        builder: (_, __) => const Scaffold(body: Text('Level complete')),
      ),
    ]);

Widget _app(_FakePuzzleController fake) => ProviderScope(
      overrides: [
        currentPuzzleProvider.overrideWith((ref) => Stream.value(_puzzle)),
        puzzleControllerProvider.overrideWithValue(fake),
        ambientEnabledProvider.overrideWithValue(false),
        // Backend-derived values stubbed; no signed-in user so commitWin skips
        // the optimistic profile bump (keeps the test DB- and Firebase-free).
        coinsProvider.overrideWithValue(0),
        nextLevelProvider.overrideWithValue(1),
        currentUserProvider.overrideWithValue(null),
      ],
      child: MaterialApp.router(routerConfig: _router()),
    );

void main() {
  testWidgets('renders the board + wheel for the current puzzle', (tester) async {
    await tester.pumpWidget(_app(_FakePuzzleController()));
    await tester.pump(); // stream emits + postframe load
    await tester.pump(); // rebuild with the loaded session
    expect(find.text('I'), findsWidgets);
    expect(find.text('F'), findsWidgets);
  });

  testWidgets('completing the only word records the result and navigates',
      (tester) async {
    final fake = _FakePuzzleController();
    await tester.pumpWidget(_app(fake));
    await tester.pump();
    await tester.pump();

    final container =
        ProviderScope.containerOf(tester.element(find.byType(GamePage)));
    final g = container.read(gameSessionProvider.notifier);
    g.touchLetter(0);
    g.touchLetter(1);
    g.endSelection(); // forms "IF", the only answer -> complete

    // Let the completion listener fire (commitWin + navigate).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(fake.recorded, isTrue);
    expect(find.text('Level complete'), findsOneWidget);
  });
}
