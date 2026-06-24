import 'package:agape_logos_game/features/home/presentation/widgets/withdraw_gift_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the Withdraw Gift label and fires onPressed',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: WithdrawGiftButton(onPressed: () => taps++)),
      ),
    );
    await tester.pump();

    expect(find.text('Withdraw Gift'), findsOneWidget);
    expect(find.text('Bonus Gift'), findsNothing);

    await tester.tap(find.text('Withdraw Gift'));
    expect(taps, 1);
  });
}
