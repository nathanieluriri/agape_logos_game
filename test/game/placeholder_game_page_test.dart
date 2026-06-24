import 'package:agape_logos_game/game/placeholder_game_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the coming-soon placeholder', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PlaceholderGamePage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Game coming soon'), findsOneWidget);
  });
}
