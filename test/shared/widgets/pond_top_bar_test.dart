// test/shared/widgets/pond_top_bar_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agape_logos_game/shared/widgets/pond_top_bar.dart';
import 'package:agape_logos_game/shared/widgets/coin_pill.dart';

void main() {
  testWidgets('PondTopBar shows settings + coin pill and fires callbacks',
      (tester) async {
    var settings = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PondTopBar(coins: 9999, onSettings: () => settings++),
      ),
    ));
    expect(find.byType(CoinPill), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Settings'));
    expect(settings, 1);
  });
}
