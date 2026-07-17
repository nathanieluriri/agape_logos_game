// test/app/pond_shell_test.dart
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agape_logos_game/app/pond_shell.dart';
import 'package:agape_logos_game/game/ambient/ambient_providers.dart';

void main() {
  testWidgets('PondShell omits the Flame layer when ambient is disabled',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [ambientEnabledProvider.overrideWithValue(false)],
      child: const MaterialApp(
        home: PondShell(child: Text('content', textDirection: TextDirection.ltr)),
      ),
    ));
    await tester.pump();
    expect(find.text('content'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is GameWidget), findsNothing);
  });
}
