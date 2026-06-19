import 'package:agape_logos_game/features/home/presentation/widgets/home_background.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the gradient and no GameWidget when ambient disabled',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [homeAmbientEnabledProvider.overrideWithValue(false)],
        child: const MaterialApp(home: Scaffold(body: HomeBackground())),
      ),
    );
    await tester.pump();

    expect(find.byType(GameWidget), findsNothing);
    expect(find.byType(DecoratedBox), findsWidgets);
  });
}
