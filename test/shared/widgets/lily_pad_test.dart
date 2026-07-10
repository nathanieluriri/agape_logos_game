// test/shared/widgets/lily_pad_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agape_logos_game/shared/widgets/lily_pad.dart';

void main() {
  testWidgets('LilyPad paints and lays out its child', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Center(
        child: LilyPad(
          size: 180,
          palette: LilyPadPalette.green,
          rotationDegrees: 20,
          child: Text('Lv.26'),
        ),
      ),
    ));
    expect(find.text('Lv.26'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('LilyPad renders the smooth shape', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Center(
        child: LilyPad(
          size: 104,
          palette: LilyPadPalette.bonusBlue,
          shape: PadShape.smooth,
          child: Text('Bonus'),
        ),
      ),
    ));
    expect(find.text('Bonus'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('palettes differ between green and bonus blue', () {
    expect(LilyPadPalette.green.fillGradient,
        isNot(LilyPadPalette.bonusBlue.fillGradient));
  });

  testWidgets('LilyPad accepts a lift and repaints without error across values',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Center(
        child: LilyPad(size: 180, palette: LilyPadPalette.green, lift: 0),
      ),
    ));
    // Rebuild at full lift: the shadow layer recomputes (blur/offset/opacity).
    await tester.pumpWidget(const MaterialApp(
      home: Center(
        child: LilyPad(size: 180, palette: LilyPadPalette.green, lift: 1),
      ),
    ));
    // And an intermediate value.
    await tester.pumpWidget(const MaterialApp(
      home: Center(
        child: LilyPad(size: 180, palette: LilyPadPalette.green, lift: 0.5),
      ),
    ));
    expect(tester.takeException(), isNull);
  });

  testWidgets('LilyPad lift defaults to 0 (shadowless-safe, golden-stable)',
      (tester) async {
    // No lift argument: must still build (default 0) exactly like the existing
    // call sites that never pass lift.
    await tester.pumpWidget(const MaterialApp(
      home: Center(
        child: LilyPad(size: 120, palette: LilyPadPalette.bonusBlue),
      ),
    ));
    expect(tester.takeException(), isNull);
  });
}
