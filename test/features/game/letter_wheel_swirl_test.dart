import 'package:agape_logos_game/features/game/presentation/widgets/letter_wheel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wheel({
    required List<String> letters,
    required List<int> ids,
    int swirlTick = 0,
    void Function(int)? onTouch,
  }) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: LetterWheel(
          letters: letters,
          selected: const [],
          ids: ids,
          swirlTick: swirlTick,
          onTouch: onTouch ?? (_) {},
          onEnd: () {},
        ),
      ),
    ),
  );

  testWidgets('a swirl travels, ignores input mid-flight, and settles on the '
      'new slots', (tester) async {
    await tester.pumpWidget(
      wheel(letters: const ['A', 'B', 'C', 'D'], ids: const [0, 1, 2, 3]),
    );
    final startA = tester.getCenter(find.text('A'));

    // Scramble: A moves from slot 0 to slot 2 (ids permuted), swirl armed.
    var touched = 0;
    await tester.pumpWidget(
      wheel(
        letters: const ['C', 'D', 'A', 'B'],
        ids: const [2, 3, 0, 1],
        swirlTick: 1,
        onTouch: (_) => touched++,
      ),
    );

    // Mid-swirl: A is airborne (neither at its old nor its new center), and
    // a drag over the wheel selects nothing.
    await tester.pump(const Duration(milliseconds: 450));
    final midA = tester.getCenter(find.text('A'));
    await tester.drag(find.byType(LetterWheel), const Offset(10, 10),
        warnIfMissed: false);
    expect(touched, 0);

    // Settled: A sits at slot 2's center (bottom of a 4-node wheel).
    await tester.pumpAndSettle();
    final endA = tester.getCenter(find.text('A'));
    final expected = LetterWheel.centersIn(const Size(260, 260), 4)[2];
    final wheelTopLeft = tester.getTopLeft(find.byType(LetterWheel));
    expect((endA - (wheelTopLeft + expected)).distance, lessThan(1.0));
    expect(endA, isNot(equals(startA)));
    expect((midA - endA).distance, greaterThan(4.0));
  });
}
