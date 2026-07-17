import 'package:agape_logos_game/features/game/presentation/widgets/dictionary_sheet.dart';
import 'package:agape_logos_game/features/puzzles/domain/puzzle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _targets = [
  PuzzleAnswer(
    word: 'POND',
    length: 4,
    definition: 'A small body of still water.',
  ),
  PuzzleAnswer(word: 'PODS', length: 4, definition: 'Seed cases.'),
  PuzzleAnswer(word: 'SNAP', length: 4, definition: null),
];

Widget _app({
  List<PuzzleAnswer> targets = _targets,
  Set<String> found = const {'POND'},
  Map<String, int> revealed = const {'PODS': 1},
}) {
  return MaterialApp(
    home: Scaffold(
      body: DictionarySheetContent(
        targets: targets,
        found: found,
        revealed: revealed,
      ),
    ),
  );
}

void main() {
  testWidgets('found word shows uppercase word and its definition',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    expect(find.text('POND'), findsOneWidget);
    expect(find.text('A small body of still water.'), findsOneWidget);
    // Unfound definitions never leak.
    expect(find.text('Seed cases.'), findsNothing);
  });

  testWidgets('partially revealed word shows the masked slot line',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    // PODS with one hint-revealed letter: visible P, three masked slots.
    expect(find.text('P _ _ _', findRichText: true), findsOneWidget);
  });

  testWidgets('untouched word is fully masked and marked hidden',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump();

    // SNAP with nothing revealed: four masked slots.
    expect(find.text('_ _ _ _', findRichText: true), findsOneWidget);
    // Both unfound entries carry the hidden hint.
    expect(find.text('Still hidden in the pond.'), findsNWidgets(2));
  });

  testWidgets('found word with a null definition shows the fallback line',
      (tester) async {
    await tester.pumpWidget(_app(found: const {'POND', 'SNAP'}));
    await tester.pump();

    expect(find.text('SNAP'), findsOneWidget);
    expect(find.text('No definition for this one yet.'), findsOneWidget);
    expect(find.text('Still hidden in the pond.'), findsOneWidget);
  });
}
