// test/shared/widgets/pond_background_test.dart
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agape_logos_game/shared/widgets/pond_background.dart';

void main() {
  testWidgets('PondBackground passes the child through and owns no game',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: PondBackground(child: Text('content'))),
    ));
    await tester.pump();
    expect(find.text('content'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is GameWidget), findsNothing);
  });
}
