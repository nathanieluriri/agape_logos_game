import 'package:agape_logos_game/features/multiplayer/presentation/widgets/join_code_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('typing a 4-letter code enables Join and reports it uppercased',
      (tester) async {
    String? submitted;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: JoinCodeEntry(onSubmit: (c) => submitted = c),
      ),
    ));
    await tester.enterText(find.byType(TextField), 'abcd');
    await tester.pump();
    await tester.tap(find.text('Join'));
    await tester.pump();
    expect(submitted, 'ABCD');
  });

  testWidgets('an incomplete code keeps Join disabled', (tester) async {
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: JoinCodeEntry(onSubmit: (_) => calls++)),
    ));
    await tester.enterText(find.byType(TextField), 'AB');
    await tester.pump();
    await tester.tap(find.text('Join'));
    await tester.pump();
    expect(calls, 0);
  });

  testWidgets('the wheel toggle swaps input modes', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: JoinCodeEntry(onSubmit: (_) {})),
    ));
    expect(find.byType(TextField), findsOneWidget);
    await tester.tap(find.text('Use the wheel'));
    await tester.pump();
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Type it instead'), findsOneWidget);
  });
}
