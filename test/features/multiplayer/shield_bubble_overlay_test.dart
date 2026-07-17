import 'package:agape_logos_game/features/multiplayer/presentation/widgets/shield_bubble_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host({required bool armed}) => MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 260, height: 260,
        child: ShieldBubbleOverlay(armed: armed),
      ),
    ),
  );

  Finder paintFinder() => find.descendant(
    of: find.byType(ShieldBubbleOverlay),
    matching: find.byType(CustomPaint),
  );

  testWidgets('nothing renders while unarmed', (tester) async {
    await tester.pumpWidget(host(armed: false));
    expect(paintFinder(), findsNothing);
  });

  testWidgets('arming blooms the bubble and it stays on screen', (tester) async {
    await tester.pumpWidget(host(armed: false));
    await tester.pumpWidget(host(armed: true));
    await tester.pump(const Duration(milliseconds: 100));
    expect(paintFinder(), findsWidgets);
    await tester.pumpAndSettle();
    expect(paintFinder(), findsWidgets);
  });

  double popValue(WidgetTester tester) =>
      (tester.widget<CustomPaint>(paintFinder()).painter as dynamic).pop
          as double;

  testWidgets('consuming the shield ripples, then clears', (tester) async {
    await tester.pumpWidget(host(armed: true));
    await tester.pumpAndSettle();
    await tester.pumpWidget(host(armed: false));

    // Mid-pop, early sample: strictly between 0 and 1, i.e. actually
    // mid-sweep. A `pop > 0` check alone is satisfied by the exact
    // pinned-at-1 regression this guards against (the pop
    // TweenAnimationBuilder's element reused across the branch flip, same
    // Tween(begin:0,end:1) shape as the bloom branch, its t stuck at the
    // bloom's already-settled 1) - the same bug class the frost overlay
    // hit. Bounding above 1 rules that failure mode out.
    await tester.pump(const Duration(milliseconds: 100));
    expect(paintFinder(), findsWidgets);
    final popAt100ms = popValue(tester);
    expect(popAt100ms, greaterThan(0.0));
    expect(popAt100ms, lessThan(1.0));

    // Later sample: the sweep has actually advanced past the 100ms value,
    // not frozen there (a pinned tween would produce the same reading
    // twice).
    await tester.pump(const Duration(milliseconds: 200));
    final popAt300ms = popValue(tester);
    expect(popAt300ms, greaterThan(popAt100ms));

    // Fully elapsed: gone.
    await tester.pump(const Duration(milliseconds: 600));
    expect(paintFinder(), findsNothing);
  });

  testWidgets(
    're-arming mid-pop shows the bloom/static frame, not the dissolving pop',
    (tester) async {
      await tester.pumpWidget(host(armed: true));
      await tester.pumpAndSettle();
      await tester.pumpWidget(host(armed: false));
      await tester.pump(const Duration(milliseconds: 100));
      // Confirm we are genuinely mid-pop before re-arming.
      expect(popValue(tester), greaterThan(0.0));

      // Re-armed within the pop window: the shield is active again, so the
      // overlay must show the bloom/static frame, not keep dissolving a
      // pop for a shield that no longer needs to disappear.
      await tester.pumpWidget(host(armed: true));
      await tester.pump();
      expect(popValue(tester), 0.0);

      // Drain the stale pop-clear Timer from the original disarm (its
      // sequence no longer matches, so it is a no-op by the time it fires,
      // but it is still outstanding until the clock reaches it) so the test
      // does not end with a pending timer.
      await tester.pump(const Duration(milliseconds: 400));
    },
  );
}
