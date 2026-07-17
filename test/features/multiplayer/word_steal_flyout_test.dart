import 'package:agape_logos_game/features/multiplayer/presentation/widgets/word_steal_flyout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('flyout shows the stolen word, travels, and self-removes',
      (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(builder: (c) {
            ctx = c;
            return const SizedBox.expand();
          }),
        ),
      ),
    );
    WordStealFlyout.show(
      ctx,
      label: 'LOTUS',
      from: const Offset(200, 400),
      to: const Offset(340, 60),
    );
    await tester.pump();
    expect(find.text('LOTUS'), findsOneWidget);
    final early = tester.getCenter(find.text('LOTUS'));

    await tester.pump(const Duration(milliseconds: 400));
    final mid = tester.getCenter(find.text('LOTUS'));
    expect((mid - early).distance, greaterThan(20));

    // Fully elapsed: the overlay entry removed itself.
    await tester.pumpAndSettle();
    expect(find.text('LOTUS'), findsNothing);
  });
}
