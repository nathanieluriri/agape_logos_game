// test/shared/widgets/pond_background_test.dart
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agape_logos_game/features/home/presentation/widgets/home_background.dart';
import 'package:agape_logos_game/shared/widgets/pond_background.dart';

void main() {
  testWidgets('PondBackground omits the Flame layer when ambient is disabled',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [homeAmbientEnabledProvider.overrideWithValue(false)],
      child: const MaterialApp(
        home: Scaffold(body: PondBackground(child: Text('content'))),
      ),
    ));
    await tester.pump();
    expect(find.text('content'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is GameWidget), findsNothing);
  });
}
