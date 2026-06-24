import 'package:agape_logos_game/features/home/presentation/widgets/home_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the grouped currency and reacts to the add tap',
      (tester) async {
    var added = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: HomeTopBar(onAdd: () => added++)),
        ),
      ),
    );
    // Let the count-up animation finish.
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('9,999'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_circle));
    expect(added, 1);
  });
}
