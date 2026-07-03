import 'package:agape_logos_game/core/design/tokens/colors.dart';
import 'package:agape_logos_game/features/tutorial/presentation/widgets/spotlight_scrim.dart';
import 'package:agape_logos_game/features/tutorial/presentation/widgets/tutorial_message_pill.dart';
import 'package:agape_logos_game/features/tutorial/presentation/widgets/tutorial_trace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpotlightBarrier', () {
    testWidgets('passes taps through the wheel circle, absorbs elsewhere',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(children: [
          // A big tappable region under the barrier.
          Positioned(
            left: 100,
            top: 100,
            width: 100,
            height: 100,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => taps++,
            ),
          ),
          const Positioned.fill(
            child: SpotlightBarrier(
              wheelCenter: Offset(150, 150),
              wheelRadius: 40,
            ),
          ),
        ]),
      ));

      // Inside the circle: the tap reaches the button below.
      await tester.tapAt(const Offset(150, 150));
      expect(taps, 1);

      // Over the button but outside the circle: absorbed by the barrier.
      await tester.tapAt(const Offset(110, 105));
      expect(taps, 1);
    });

    testWidgets('a null wheel center blocks everything', (tester) async {
      var taps = 0;
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => taps++,
            ),
          ),
          const Positioned.fill(child: SpotlightBarrier()),
        ]),
      ));
      await tester.tapAt(const Offset(400, 300));
      expect(taps, 0);
    });
  });

  group('TutorialMessagePill', () {
    testWidgets('renders the message with the target word accented',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Center(
            child: TutorialMessagePill(
              message: 'Great! Now add the word FIT.',
              highlight: 'FIT',
            ),
          ),
        ),
      ));
      expect(
        find.text('Great! Now add the word FIT.', findRichText: true),
        findsOneWidget,
      );

      // Every accent-colored span, concatenated, is exactly the highlight.
      final richText = tester.widget<RichText>(find.descendant(
        of: find.byType(TutorialMessagePill),
        matching: find.byType(RichText),
      ));
      var accented = '';
      richText.text.visitChildren((span) {
        if (span is TextSpan && span.style?.color == AppColors.accent) {
          accented += span.text ?? '';
        }
        return true;
      });
      expect(accented, 'FIT');
    });

    testWidgets('renders plainly when no highlight is given', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Center(
            child: TutorialMessagePill(
              message: 'Perfect! Find every word to clear the pond.',
            ),
          ),
        ),
      ));
      expect(
        find.text(
          'Perfect! Find every word to clear the pond.',
          findRichText: true,
        ),
        findsOneWidget,
      );
    });
  });

  group('positionAlong', () {
    const points = [Offset(0, 0), Offset(10, 0), Offset(10, 10)];

    test('returns the endpoints at t = 0 and t = 1', () {
      expect(positionAlong(points, 0), Offset.zero);
      expect(positionAlong(points, 1), const Offset(10, 10));
    });

    test('interpolates linearly over cumulative segment lengths', () {
      expect(positionAlong(points, 0.5), const Offset(10, 0));
      expect(positionAlong(points, 0.25), const Offset(5, 0));
      expect(positionAlong(points, 0.75), const Offset(10, 5));
    });

    test('clamps t and tolerates degenerate polylines', () {
      expect(positionAlong(points, -1), Offset.zero);
      expect(positionAlong(points, 2), const Offset(10, 10));
      expect(positionAlong(const [Offset(3, 4)], 0.5), const Offset(3, 4));
      expect(
        positionAlong(const [Offset(1, 1), Offset(1, 1)], 0.7),
        const Offset(1, 1),
      );
    });
  });
}
