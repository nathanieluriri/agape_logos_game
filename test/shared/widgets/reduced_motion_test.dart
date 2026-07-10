import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agape_logos_game/shared/widgets/float_motion.dart';
import 'package:agape_logos_game/shared/widgets/lily_pad.dart';
import 'package:agape_logos_game/shared/widgets/lily_pad_button.dart';
import 'package:agape_logos_game/shared/widgets/lotus_mark.dart';

void main() {
  testWidgets('LilyPadButton runs no perpetual idle animation under reduced motion',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Scaffold(
          body: Center(
            child: LilyPadButton(
              size: 180,
              palette: LilyPadPalette.green,
              content: const Text('x'),
              onPressed: () {},
            ),
          ),
        ),
      ),
    ));
    // If reduced motion is honored the idle controller is not repeating, so the
    // tree settles. If it were animating forever, pumpAndSettle would time out.
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('LotusMark runs no perpetual idle animation under reduced motion',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Scaffold(body: Center(child: LotusMark())),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('FloatMotion inserts no Transform under reduced motion',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Scaffold(
          body: Center(
            child: FloatMotion(child: Text('pad')),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('pad'), findsOneWidget);
    // Scope to FloatMotion's own subtree: MaterialApp's page transition
    // (ZoomPageTransitionsBuilder on Android) already puts 2 Transforms in the
    // tree, so a bare find.byType(Transform) would never be empty.
    expect(
      find.descendant(
        of: find.byType(FloatMotion),
        matching: find.byType(Transform),
      ),
      findsNothing,
    );
  });
}
