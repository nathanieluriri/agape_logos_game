import 'package:agape_logos_game/features/game/presentation/widgets/letter_wheel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders one node per letter and reports release', (tester) async {
    final touched = <int>[];
    var ended = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: LetterWheel(
            letters: const ['I', 'F'],
            selected: const [],
            onTouch: touched.add,
            onEnd: () => ended++,
          ),
        ),
      ),
    ));
    expect(find.text('I'), findsOneWidget);
    expect(find.text('F'), findsOneWidget);

    // A drag starting on the first node reports a touch and an end on release.
    // (A press-release with no movement fires onTap, not onPan*, so the gesture
    // must move past the touch slop to trigger the pan callbacks.)
    final start = tester.getCenter(find.text('I'));
    final gesture = await tester.startGesture(start);
    await gesture.moveTo(start + const Offset(20, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(touched, contains(0));
    expect(ended, 1);
  });

  testWidgets('selected nodes paint highlighted (no exception)', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: LetterWheel(
            letters: const ['T', 'O', 'P'],
            selected: const [0, 1],
            onTouch: (_) {},
            onEnd: () {},
          ),
        ),
      ),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
