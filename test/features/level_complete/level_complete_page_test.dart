// test/features/level_complete/level_complete_page_test.dart
import 'package:agape_logos_game/core/design/tokens/durations.dart';
import 'package:agape_logos_game/features/level_complete/presentation/pages/level_complete_page.dart';
import 'package:agape_logos_game/features/level_complete/presentation/widgets/level_progress_bar.dart';
import 'package:agape_logos_game/features/player/application/player_controller.dart';
import 'package:agape_logos_game/features/player/application/player_state.dart';
import 'package:agape_logos_game/features/profile/application/profile_providers.dart';
import 'package:agape_logos_game/features/puzzles/domain/puzzle.dart';
import 'package:agape_logos_game/game/ambient/ambient_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _words = [
  PuzzleAnswer(word: 'CAB', length: 3, definition: 'a taxi'),
  PuzzleAnswer(word: 'ARC', length: 3, definition: 'a curve'),
];

/// Forces [levelCompletionProvider] to a fixed value so the guard is
/// deterministic from the first frame (no post-mount seeding race).
class _StubPlayer extends PlayerController {
  _StubPlayer(this._summary);
  final LevelSummary? _summary;
  @override
  LevelSummary? build() => _summary;
}

Widget _host(LevelSummary? summary) {
  final router = GoRouter(
    initialLocation: '/level-complete',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: Text('stub-home')),
      ),
      GoRoute(
        path: '/level-complete',
        builder: (_, __) => const LevelCompletePage(),
      ),
      // Reachable from the Play/settings/store callbacks; stubbed so taps route.
      GoRoute(path: '/game', builder: (_, __) => const SizedBox.shrink()),
      GoRoute(path: '/settings', builder: (_, __) => const SizedBox.shrink()),
      GoRoute(path: '/store', builder: (_, __) => const SizedBox.shrink()),
    ],
  );
  return ProviderScope(
    overrides: [
      ambientEnabledProvider.overrideWithValue(false),
      coinsProvider.overrideWithValue(0),
      nextLevelProvider.overrideWithValue(4),
      levelCompletionProvider.overrideWith(() => _StubPlayer(summary)),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets(
      'renders the real summary (bar + final numeral) with a Dictionary pad, '
      'no Bonus/Withdraw', (tester) async {
    await tester.pumpWidget(_host(
      const LevelSummary(
        completedLevel: 3,
        wordsFound: 2,
        totalWords: 2,
        words: _words,
      ),
    ));
    // Let the fill + count-up + any bloom run to their end.
    await tester.pump();
    await tester.pump(AppDurations.slow + const Duration(milliseconds: 400));

    expect(find.byType(LevelProgressBar), findsOneWidget);
    expect(find.text('Level 3 Completed!'), findsOneWidget);
    expect(find.text('2/2'), findsOneWidget);
    expect(find.text('0/0'), findsNothing);
    expect(find.bySemanticsLabel('Dictionary'), findsOneWidget);
    expect(find.bySemanticsLabel('Bonus Gift'), findsNothing);
    expect(find.bySemanticsLabel('Withdraw'), findsNothing);
  });

  testWidgets('the Dictionary pad opens the words from the completed level',
      (tester) async {
    await tester.pumpWidget(_host(
      const LevelSummary(
        completedLevel: 3,
        wordsFound: 2,
        totalWords: 2,
        words: _words,
      ),
    ));
    await tester.pump();
    await tester.pump(AppDurations.slow + const Duration(milliseconds: 400));

    await tester.tap(find.bySemanticsLabel('Dictionary'));
    // Bounded pumps, never pumpAndSettle: the play pads run a perpetual
    // FloatMotion idle bob, so the tree never settles.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // The reused session dictionary sheet shows the solved words + definitions.
    expect(find.text('CAB'), findsOneWidget);
    expect(find.text('a taxi'), findsOneWidget);
    expect(find.text('ARC'), findsOneWidget);
  });

  testWidgets('null summary bounces Home and never shows an empty 0/0 bar',
      (tester) async {
    await tester.pumpWidget(_host(null));
    // First frame paints the fallback; the post-frame redirect then runs.
    await tester.pump();
    await tester.pump();

    expect(find.text('stub-home'), findsOneWidget);
    expect(find.byType(LevelProgressBar), findsNothing);
    expect(find.text('0/0'), findsNothing);
  });
}
