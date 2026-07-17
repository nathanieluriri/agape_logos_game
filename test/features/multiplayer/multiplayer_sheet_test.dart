// test/features/multiplayer/multiplayer_sheet_test.dart
import 'package:agape_logos_game/features/multiplayer/application/resume_providers.dart';
import 'package:agape_logos_game/features/multiplayer/domain/active_match.dart';
import 'package:agape_logos_game/features/multiplayer/domain/challenge_invite.dart';
import 'package:agape_logos_game/features/multiplayer/presentation/widgets/multiplayer_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The sheet is a ConsumerWidget (its Resume entry watches the challenge +
  // active-match providers for a count badge), so it needs a ProviderScope. The
  // overrides keep the badge providers off the network.
  Widget host(void Function(BuildContext) onOpen) => ProviderScope(
        overrides: [
          incomingChallengesProvider
              .overrideWith((ref) => Stream.value(const <ChallengeInvite>[])),
          activeMatchesProvider
              .overrideWith((ref) async => const <ActiveMatch>[]),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => onOpen(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

  // A phone-tall viewport: the chooser now has three entries, and the default
  // 600px test surface caps a non-scroll-controlled bottom sheet below their
  // combined height.
  void tallView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('choosing Create returns MultiplayerChoice.create',
      (tester) async {
    tallView(tester);
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
    tallView(tester);
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
