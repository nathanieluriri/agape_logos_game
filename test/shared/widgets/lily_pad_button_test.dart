// test/shared/widgets/lily_pad_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agape_logos_game/shared/widgets/lily_pad.dart';
import 'package:agape_logos_game/shared/widgets/lily_pad_button.dart';

void main() {
  testWidgets('LilyPadButton fires onPressed and exposes a semantics label',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: LilyPadButton(
          size: 180,
          palette: LilyPadPalette.green,
          content: const Text('Play'),
          semanticLabel: 'Play level 26',
          onPressed: () => taps++,
        ),
      ),
    ));
    await tester.tap(find.byType(LilyPadButton));
    await tester.pump(const Duration(milliseconds: 200));
    expect(taps, 1);
    expect(find.bySemanticsLabel('Play level 26'), findsOneWidget);
  });
}
