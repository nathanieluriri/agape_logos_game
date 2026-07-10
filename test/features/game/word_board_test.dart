import 'package:agape_logos_game/core/design/tokens/durations.dart';
import 'package:agape_logos_game/features/game/presentation/widgets/word_board.dart';
import 'package:agape_logos_game/features/puzzles/domain/puzzle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _targets = [
  PuzzleAnswer(word: 'TO', length: 2, definition: null),
  PuzzleAnswer(word: 'TOP', length: 3, definition: null),
];

void main() {
  testWidgets('found words show their letters; unfound stay blank', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: WordBoard(targets: _targets, found: {'TO'}, revealed: {}),
      ),
    ));
    await tester.pump();
    // "TO" found -> its two letters render; "TOP" unfound/unrevealed renders none.
    expect(find.text('T'), findsOneWidget); // only the T from TO
    expect(find.text('O'), findsOneWidget);
    expect(find.text('P'), findsNothing);
  });

  testWidgets('a revealed leading letter shows even when unfound', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: WordBoard(targets: _targets, found: {}, revealed: {'TOP': 1}),
      ),
    ));
    await tester.pump();
    expect(find.text('T'), findsOneWidget); // first letter of TOP revealed
    expect(find.text('P'), findsNothing);
  });

  testWidgets('finding a word cascades its tiles to filled', (tester) async {
    Widget board(Set<String> found) => MaterialApp(
          home: Scaffold(
            body: WordBoard(targets: _targets, found: found, revealed: const {}),
          ),
        );

    // Before the word is found, its letters are absent.
    await tester.pumpWidget(board(const {}));
    await tester.pump();
    expect(find.text('T'), findsNothing);
    expect(find.text('O'), findsNothing);

    // Find "TO": the row flips and the tiles bloom left to right.
    await tester.pumpWidget(board(const {'TO'}));
    await tester.pump(); // kick the controllers
    // Pump past the longest stagger + a full reveal so the cascade completes.
    await tester.pump(AppDurations.tileStagger * 2 + AppDurations.tileReveal);
    await tester.pumpAndSettle();

    // Both letters are present and the animation has settled (no hang).
    expect(find.text('T'), findsOneWidget); // only the T from TO
    expect(find.text('O'), findsOneWidget);
    expect(find.text('P'), findsNothing); // TOP still unfound
  });

  testWidgets('reduced motion fills found tiles immediately', (tester) async {
    Widget board(Set<String> found) => MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: WordBoard(targets: _targets, found: found, revealed: const {}),
            ),
          ),
        );

    await tester.pumpWidget(board(const {}));
    await tester.pump();
    await tester.pumpWidget(board(const {'TO'}));
    await tester.pump(); // a single frame: no animation under reduced motion

    expect(find.text('T'), findsOneWidget);
    expect(find.text('O'), findsOneWidget);
    await tester.pumpAndSettle(); // must complete, proving nothing loops
  });
}
