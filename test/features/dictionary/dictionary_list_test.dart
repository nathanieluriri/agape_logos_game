import 'package:agape_logos_game/features/dictionary/domain/dictionary_entry.dart';
import 'package:agape_logos_game/features/dictionary/presentation/widgets/dictionary_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(List<DictionaryEntry> entries) =>
    MaterialApp(home: Scaffold(body: DictionaryList(entries: entries)));

const _entries = [
  DictionaryEntry(word: 'CAB', definition: 'a taxi', tier: 'easy', level: null),
  DictionaryEntry(
      word: 'ABLE', definition: 'having the power', tier: 'medium', level: null),
  DictionaryEntry(word: 'ZIP', definition: 'fasten', tier: 'hard', level: null),
];

void main() {
  testWidgets('lists every word with its definition, grouped by tier',
      (tester) async {
    await tester.pumpWidget(_host(_entries));
    await tester.pump();
    expect(find.text('CAB'), findsOneWidget);
    expect(find.text('a taxi'), findsOneWidget);
    expect(find.text('ABLE'), findsOneWidget);
    expect(find.text('ZIP'), findsOneWidget);
    // Tier section labels are present.
    expect(find.text('Easy'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('Hard'), findsOneWidget);
  });

  testWidgets('search filters by word and definition (case-insensitive)',
      (tester) async {
    await tester.pumpWidget(_host(_entries));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'taxi');
    await tester.pump();
    expect(find.text('CAB'), findsOneWidget); // matched via its definition
    expect(find.text('ABLE'), findsNothing);
    expect(find.text('ZIP'), findsNothing);
  });

  testWidgets('shows a no-match notice when the query matches nothing',
      (tester) async {
    await tester.pumpWidget(_host(_entries));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pump();
    expect(find.textContaining('No words match'), findsOneWidget);
  });
}
