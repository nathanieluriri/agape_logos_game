// test/shared/widgets/pond_pill_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agape_logos_game/shared/widgets/pond_pill_button.dart';

void main() {
  testWidgets('PondPillButton renders its label and fires onPressed',
      (tester) async {
    var presses = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: PondPillButton(
            label: 'Okay',
            onPressed: () => presses++,
          ),
        ),
      ),
    ));
    expect(find.text('Okay'), findsOneWidget);
    await tester.tap(find.byType(PondPillButton));
    await tester.pump(const Duration(milliseconds: 200));
    expect(presses, 1);
  });

  testWidgets('PondPillButton renders every variant', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            PondPillButton(label: 'Primary', onPressed: () {}),
            PondPillButton(
              label: 'Quiet',
              variant: PondPillVariant.quiet,
              onPressed: () {},
            ),
            PondPillButton(
              label: 'Delete',
              variant: PondPillVariant.danger,
              icon: Icons.delete_outline,
              onPressed: () {},
            ),
          ],
        ),
      ),
    ));
    expect(find.text('Primary'), findsOneWidget);
    expect(find.text('Quiet'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });
}
