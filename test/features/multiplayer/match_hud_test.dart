import 'package:agape_logos_game/features/multiplayer/presentation/widgets/match_hud.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child, {double width = 320}) => MaterialApp(
        home: Scaffold(
          body: SizedBox(width: width, child: child),
        ),
      );

  testWidgets('lays out without overflow at 320dp with a long opponent name',
      (tester) async {
    await tester.pumpWidget(host(
      MatchHud(
        myScore: 128,
        myWords: 5,
        opponentName: 'A Really Long Opponent Display Name Here',
        opponentWords: 3,
        opponentConnected: true,
        endsAt: DateTime.now().add(const Duration(minutes: 5)),
        onDictionary: () {},
      ),
    ));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('128'), findsOneWidget);
  });

  testWidgets('forfeit affordance is hidden when onForfeit is null',
      (tester) async {
    await tester.pumpWidget(host(
      MatchHud(
        myScore: 1,
        myWords: 0,
        opponentName: 'Opp',
        opponentWords: 0,
        opponentConnected: false,
        endsAt: DateTime.now().add(const Duration(minutes: 5)),
        onDictionary: () {},
      ),
    ));
    await tester.pump();

    expect(find.bySemanticsLabel('Forfeit match'), findsNothing);
  });

  testWidgets('forfeit affordance appears and fires onForfeit when provided',
      (tester) async {
    var fired = false;
    await tester.pumpWidget(host(
      MatchHud(
        myScore: 1,
        myWords: 0,
        opponentName: 'Opp',
        opponentWords: 0,
        opponentConnected: false,
        endsAt: DateTime.now().add(const Duration(minutes: 5)),
        onDictionary: () {},
        onForfeit: () => fired = true,
      ),
    ));
    await tester.pump();

    expect(find.bySemanticsLabel('Forfeit match'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Forfeit match'));
    await tester.pump();
    expect(fired, isTrue);
  });

  testWidgets('dictionary button fires onDictionary', (tester) async {
    var fired = false;
    await tester.pumpWidget(host(
      MatchHud(
        myScore: 1,
        myWords: 0,
        opponentName: 'Opp',
        opponentWords: 0,
        opponentConnected: false,
        endsAt: DateTime.now().add(const Duration(minutes: 5)),
        onDictionary: () => fired = true,
      ),
    ));
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('Dictionary'));
    await tester.pump();
    expect(fired, isTrue);
  });

  testWidgets('timer shows m:ss under 1h', (tester) async {
    await tester.pumpWidget(host(
      MatchHud(
        myScore: 1,
        myWords: 0,
        opponentName: 'Opp',
        opponentWords: 0,
        opponentConnected: false,
        endsAt: DateTime.now().add(const Duration(minutes: 5, seconds: 59)),
        onDictionary: () {},
      ),
    ));
    await tester.pump();

    expect(find.textContaining(':'), findsWidgets);
    expect(find.textContaining('h '), findsNothing);
  });

  testWidgets('timer shows h mm at/over 1h', (tester) async {
    await tester.pumpWidget(host(
      MatchHud(
        myScore: 1,
        myWords: 0,
        opponentName: 'Opp',
        opponentWords: 0,
        opponentConnected: false,
        endsAt:
            DateTime.now().add(const Duration(hours: 5, minutes: 47, seconds: 10)),
        onDictionary: () {},
      ),
    ));
    await tester.pump();

    expect(find.textContaining('h '), findsOneWidget);
  });
}
