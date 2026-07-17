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

  testWidgets('consuming the shield ripples, then clears', (tester) async {
    await tester.pumpWidget(host(armed: true));
    await tester.pumpAndSettle();
    await tester.pumpWidget(host(armed: false));
    // Mid-pop: still visible, and actually rippling (pop > 0) rather than
    // pinned at the settled bloom frame. Bare presence would still pass if
    // the pop TweenAnimationBuilder's element got reused across the branch
    // flip (same shape, same Tween(begin:0,end:1) as the bloom branch) and
    // its t stayed pinned at the bloom's already-settled 1 - the same bug
    // class the frost overlay hit, where the fix was asserting a rendered
    // property (there: icon size), not just presence.
    await tester.pump(const Duration(milliseconds: 100));
    expect(paintFinder(), findsWidgets);
    final painter = tester.widget<CustomPaint>(paintFinder()).painter as dynamic;
    expect(painter.pop, greaterThan(0.0));
    // Fully elapsed: gone.
    await tester.pump(const Duration(milliseconds: 600));
    expect(paintFinder(), findsNothing);
  });
}
