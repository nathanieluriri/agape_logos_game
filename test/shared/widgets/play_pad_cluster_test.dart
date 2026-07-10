import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agape_logos_game/shared/widgets/float_motion.dart';
import 'package:agape_logos_game/shared/widgets/play_pad_cluster.dart';

void main() {
  testWidgets('PlayPadCluster fires both callbacks and labels both pads',
      (tester) async {
    var plays = 0;
    var secondaries = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: PlayPadCluster(
            nextLabel: 'Lv.26',
            onPlay: () => plays++,
            secondaryIcon: const Icon(Icons.account_balance_wallet),
            secondaryLabel: 'Withdraw',
            onSecondary: () => secondaries++,
          ),
        ),
      ),
    ));
    expect(find.bySemanticsLabel('Play Lv.26'), findsOneWidget);
    expect(find.bySemanticsLabel('Withdraw'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Play Lv.26'));
    await tester.tap(find.bySemanticsLabel('Withdraw'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(plays, 1);
    expect(secondaries, 1);
  });

  testWidgets('both pads float via FloatMotion (out of phase)', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: PlayPadCluster(
            nextLabel: 'Lv.26',
            onPlay: () {},
            secondaryIcon: const Icon(Icons.account_balance_wallet),
            secondaryLabel: 'Withdraw',
            onSecondary: () {},
          ),
        ),
      ),
    ));
    // One FloatMotion per pad. Do NOT pumpAndSettle: they animate forever.
    expect(find.byType(FloatMotion), findsNWidgets(2));
    // Labels still render on top of the animated pads.
    expect(find.text('Lv.26'), findsOneWidget);
    expect(find.text('Withdraw'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.takeException(), isNull);
  });
}
