// test/shared/widgets/pond_action_button_test.dart
import 'package:agape_logos_game/shared/widgets/glyphs/pond_glyph.dart';
import 'package:agape_logos_game/shared/widgets/pond_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows its label and glyph and fires onPressed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PondActionButton(
            glyph: PondGlyph.plus,
            label: 'Create a match',
            onPressed: () => taps++,
          ),
        ),
      ),
    );
    expect(find.text('Create a match'), findsOneWidget);
    expect(find.byType(PondIcon), findsOneWidget);
    await tester.tap(find.text('Create a match'));
    await tester.pump();
    expect(taps, 1);
  });
}
