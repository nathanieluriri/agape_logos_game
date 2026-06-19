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

  test('palettes differ between green and teal', () {
    expect(LilyPadPalette.green.strokeColor,
        isNot(LilyPadPalette.teal.strokeColor));
  });
}
