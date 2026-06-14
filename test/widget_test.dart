import 'package:agape_logos_game/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app renders the home placeholder', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AgapeApp()));
    await tester.pumpAndSettle();

    expect(find.text('agape_logos_game'), findsOneWidget);
  });
}
