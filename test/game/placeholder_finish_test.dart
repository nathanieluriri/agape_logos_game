// test/game/placeholder_finish_test.dart
import 'package:agape_logos_game/game/ambient/ambient_providers.dart';
import 'package:agape_logos_game/features/level_complete/presentation/pages/level_complete_page.dart';
import 'package:agape_logos_game/game/placeholder_game_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('Finish level (dev) routes to the level-complete page',
      (tester) async {
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const PlaceholderGamePage()),
      GoRoute(
        path: '/level-complete',
        builder: (_, __) => const LevelCompletePage(),
      ),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [ambientEnabledProvider.overrideWithValue(false)],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('Finish level (dev)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(LevelCompletePage), findsOneWidget);
  });
}
