import 'package:agape_logos_game/features/home/presentation/widgets/play_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the level label and fires onPressed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PlayButton(label: 'Lv.26', onPressed: () => taps++),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Lv.26'), findsOneWidget);

    await tester.tap(find.byType(PlayButton));
    await tester.pump(const Duration(milliseconds: 200));
    expect(taps, 1);
  });
}
