import 'package:agape_logos_game/core/design/tokens/durations.dart';
import 'package:agape_logos_game/features/game/presentation/widgets/combo_banner.dart';
import 'package:agape_logos_game/features/game/presentation/widgets/formed_word_pill.dart';
import 'package:agape_logos_game/features/game/presentation/widgets/game_top_bar.dart';
import 'package:agape_logos_game/features/game/presentation/widgets/letter_wheel.dart';
import 'package:agape_logos_game/features/game/presentation/widgets/wheel_action_button.dart';
import 'package:agape_logos_game/features/game/presentation/widgets/word_board.dart';
import 'package:agape_logos_game/features/puzzles/domain/puzzle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FormedWordPill shows each letter and hides when empty',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: FormedWordPill(word: 'FIT'))),
    ));
    // Let the per-letter pops settle.
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('F'), findsOneWidget);
    expect(find.text('I'), findsOneWidget);
    expect(find.text('T'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: FormedWordPill(word: ''))),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('F'), findsNothing); // previous word gone
    expect(find.byType(FormedWordPill), findsOneWidget);
  });

  // Issue #63: a rejected word (invalid / already found) must give a visible
  // signal, since the controller's haptic feedback is entirely invisible on
  // web.
  testWidgets(
    'FormedWordPill flashes a rejection alert then reverts; an accepted '
    'word never shows one',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: Center(child: FormedWordPill(word: 'FIT'))),
      ));
      await tester.pump(const Duration(milliseconds: 200));
      // A normally-accepted word never triggers the rejection message.
      expect(find.text('Not a word'), findsNothing);

      // A rejection alert arrives (the selection has already cleared to '',
      // as endSelection does on every call): the pill swaps to the red flash
      // + message in place of the letter display.
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Center(
            child: FormedWordPill(
              word: '',
              alert: FormedWordAlert(message: 'Not a word', nonce: 1),
            ),
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('Not a word'), findsOneWidget);
      expect(find.text('F'), findsNothing);

      // The flash holds only briefly, then reverts to the normal (now-empty)
      // display.
      await tester.pump(
        AppDurations.wordRejectFlash + const Duration(milliseconds: 50),
      );
      expect(find.text('Not a word'), findsNothing);
    },
  );

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

  // Issue #69: the drag rack must expose each letter to a screen reader.
  testWidgets('LetterWheel exposes a semantics label per letter node', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LetterWheel(
            letters: const ['C', 'A', 'T'],
            selected: const [],
            onTouch: (_) {},
            onEnd: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('C'), findsOneWidget);
    expect(find.bySemanticsLabel('A'), findsOneWidget);
    expect(find.bySemanticsLabel('T'), findsOneWidget);
    handle.dispose();
  });

  // Issue #69: the board must announce progress without leaking unfound
  // answers to assistive tech.
  testWidgets(
    'WordBoard announces "N of M words found" and masks unfound words',
    (tester) async {
      final handle = tester.ensureSemantics();
      const targets = [
        PuzzleAnswer(word: 'cat', length: 3, definition: null),
        PuzzleAnswer(word: 'ate', length: 3, definition: null),
      ];
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WordBoard(
              targets: targets,
              found: {'CAT'},
              revealed: {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.bySemanticsLabel('1 of 2 words found'), findsOneWidget);
      expect(find.bySemanticsLabel('CAT'), findsOneWidget);
      expect(find.bySemanticsLabel('ATE'), findsNothing);
      expect(
        find.bySemanticsLabel('3-letter word, not yet found'),
        findsOneWidget,
      );
      handle.dispose();
    },
  );
}
