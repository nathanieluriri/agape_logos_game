import 'package:agape_logos_game/shared/widgets/animated_app_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host({bool reduceMotion = false}) => MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: AnimatedAppIcon(size: 120)),
      ),
    );

void main() {
  testWidgets('draws the mark and keeps looping', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pump();

    expect(find.byType(AnimatedAppIcon), findsOneWidget);

    // Mid-loop and still animating: the draw repeats rather than running once
    // and leaving a dead frame on screen (the whole point of the interlude).
    await tester.pump(const Duration(milliseconds: 900));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pump(const Duration(milliseconds: 3000)); // past one full loop
    expect(tester.hasRunningAnimations, isTrue);

    // Settle the repeating controller so the test can finish.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('reduced motion rests on the finished mark', (tester) async {
    await tester.pumpWidget(_host(reduceMotion: true));
    await tester.pump();

    expect(find.byType(AnimatedAppIcon), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
