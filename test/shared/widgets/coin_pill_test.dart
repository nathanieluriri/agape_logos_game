// test/shared/widgets/coin_pill_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agape_logos_game/shared/widgets/coin_pill.dart';

void main() {
  testWidgets('CoinPill shows the grouped amount and fires onAdd', (
    tester,
  ) async {
    var added = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: CoinPill(amount: 9999, onAdd: () => added++)),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('9,999'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Add coins'));
    expect(added, 1);
  });
}
