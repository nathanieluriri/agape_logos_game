// test/features/multiplayer/multiplayer_sheet_test.dart
import 'package:agape_logos_game/features/multiplayer/presentation/widgets/multiplayer_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(void Function(BuildContext) onOpen) => MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => onOpen(context),
              child: const Text('Open'),
            ),
          ),
        ),
      );

  testWidgets('choosing Create returns MultiplayerChoice.create',
      (tester) async {
    MultiplayerChoice? choice;
    await tester.pumpWidget(host((context) async {
      choice = await showMultiplayerSheet(context);
    }));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Play with friends'), findsOneWidget);
    await tester.tap(find.text('Create a match'));
    await tester.pumpAndSettle();
    expect(choice, MultiplayerChoice.create);
  });

  testWidgets('choosing Join returns MultiplayerChoice.join', (tester) async {
    MultiplayerChoice? choice;
    await tester.pumpWidget(host((context) async {
      choice = await showMultiplayerSheet(context);
    }));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Join with a code'));
    await tester.pumpAndSettle();
    expect(choice, MultiplayerChoice.join);
  });
}
