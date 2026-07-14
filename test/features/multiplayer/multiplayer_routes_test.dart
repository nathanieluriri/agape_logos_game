import 'package:agape_logos_game/app/router/app_router.dart';
import 'package:agape_logos_game/features/multiplayer/application/match_providers.dart';
import 'package:agape_logos_game/features/multiplayer/data/match_remote.dart';
import 'package:agape_logos_game/features/profile/application/profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRemote implements MatchRemote {
  @override
  Future<({String matchId, String code})> create(Map<String, dynamic> s) async =>
      (matchId: 'm1', code: 'ABCD');
  @override
  Future<String> join(String code) async => 'm1';
  @override
  Future<void> ready(String matchId, {required bool ready}) async {}
  @override
  Future<void> start(String matchId) async {}
  @override
  Future<void> submit(String matchId, String word) async {}
  @override
  Future<bool> powerup(String matchId, String kind, {required String eventId}) async => true;
  @override
  Future<void> leave(String matchId) async {}

  @override
  Future<void> settle(String matchId) async {}
}

void main() {
  testWidgets('router opens the matchmaking route', (tester) async {
    appRouter.go('/multiplayer');
    await tester.pumpWidget(ProviderScope(
      overrides: [
        matchServiceProvider.overrideWithValue(_FakeRemote()),
        coinsProvider.overrideWithValue(0),
      ],
      child: MaterialApp.router(routerConfig: appRouter),
    ));
    // Bounded pumps, never pumpAndSettle: pond pads run a perpetual FloatMotion
    // idle bob, so the tree never settles.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Create a match'), findsOneWidget);
    addTearDown(() => appRouter.go('/'));
  });
}
