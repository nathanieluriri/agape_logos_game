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
}
