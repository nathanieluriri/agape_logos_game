import 'package:agape_logos_game/features/game/presentation/widgets/combo_banner.dart';
import 'package:agape_logos_game/features/game/presentation/widgets/formed_word_pill.dart';
import 'package:agape_logos_game/features/game/presentation/widgets/game_top_bar.dart';
import 'package:agape_logos_game/features/game/presentation/widgets/wheel_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FormedWordPill shows the word and hides when empty', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: FormedWordPill(word: 'FIT'))),
    ));
    await tester.pump();
    expect(find.text('FIT'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: FormedWordPill(word: ''))),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('FIT'), findsNothing); // previous word gone
    expect(find.byType(FormedWordPill), findsOneWidget);
  });

  testWidgets('ComboBanner renders praise and streak', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: ComboBanner(praise: 'Expert!', combo: 3)),
    ));
    await tester.pump();
    expect(find.text('Expert!'), findsOneWidget);
    expect(find.textContaining('3'), findsOneWidget);
  });

  testWidgets('WheelActionButton fires onTap and shows a badge', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: WheelActionButton(
            icon: Icons.lightbulb_outline,
            semanticLabel: 'Hint',
            onTap: () => taps++,
            badge: 2,
          ),
        ),
      ),
    ));
    await tester.tap(find.bySemanticsLabel('Hint'));
    expect(taps, 1);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('GameTopBar shows the level and coins', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GameTopBar(level: 2, coins: 200, onBack: () {}, onDictionary: () {}),
      ),
    ));
    await tester.pump();
    expect(find.text('Level 2'), findsOneWidget);
    // CoinPill animates the count from 0 to amount over AppDurations.slow.
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('200'), findsWidgets);
  });

  testWidgets('WheelActionButton under reduce-motion settles instantly and fires tap',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: WheelActionButton(
                icon: Icons.shuffle,
                semanticLabel: 'Shuffle',
                onTap: () => taps++,
              ),
            ),
          ),
        ),
      ),
    );
    // Widget builds without error under disableAnimations.
    expect(find.bySemanticsLabel('Shuffle'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Shuffle'));
    // pumpAndSettle must complete (Duration.zero means no lingering animation frames).
    await tester.pumpAndSettle();

    expect(taps, 1);
  });
}
