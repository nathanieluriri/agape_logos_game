import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agape_logos_game/shared/widgets/float_motion.dart';

void main() {
  testWidgets('renders a plain child (no builder) and keeps it across frames',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: FloatMotion(child: Text('pad')))),
    ));
    expect(find.text('pad'), findsOneWidget);
    // FloatMotion repeats forever, so step discrete frames (never pumpAndSettle).
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('pad'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('builder receives a lift within 0..1 while animating',
      (tester) async {
    final lifts = <double>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: FloatMotion(
            builder: (context, lift, child) {
              lifts.add(lift);
              return const Text('pad');
            },
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('pad'), findsOneWidget);
    expect(lifts, isNotEmpty);
    expect(lifts.every((l) => l >= 0.0 && l <= 1.0), isTrue);
  });

  testWidgets('reduced motion: no perpetual ticker, static at rest (lift 0)',
      (tester) async {
    double? seenLift;
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Scaffold(
          body: Center(
            child: FloatMotion(
              builder: (context, lift, child) {
                seenLift = lift;
                return const Text('pad');
              },
            ),
          ),
        ),
      ),
    ));
    // If a ticker were repeating forever, pumpAndSettle would time out.
    await tester.pumpAndSettle();
    expect(find.text('pad'), findsOneWidget);
    expect(seenLift, 0.0);
    // No Transform is inserted at rest, so the child is not wrapped in motion.
    // Scoped to FloatMotion: MaterialApp's own page transition contributes
    // Transforms to the tree regardless of this widget.
    expect(
      find.descendant(
        of: find.byType(FloatMotion),
        matching: find.byType(Transform),
      ),
      findsNothing,
    );
  });

  testWidgets('accepts custom amplitude, scaleGain, period, phase, tilt off',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: FloatMotion(
            amplitude: 12,
            scaleGain: 0.05,
            period: Duration(seconds: 4),
            phase: 0.5,
            tilt: false,
            child: Text('pad'),
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.text('pad'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
