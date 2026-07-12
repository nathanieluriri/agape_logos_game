import 'package:agape_logos_game/features/multiplayer/application/match_providers.dart';
import 'package:agape_logos_game/features/multiplayer/data/match_remote.dart';
import 'package:agape_logos_game/features/multiplayer/presentation/pages/matchmaking_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeRemote implements MatchRemote {
  String? createdWith;
  @override
  Future<({String matchId, String code})> create(Map<String, dynamic> s) async {
    createdWith = s['difficulty'] as String?;
    return (matchId: 'm1', code: 'ABCD');
  }
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
}

GoRouter _router() => GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const MatchmakingPage()),
      GoRoute(
        path: '/multiplayer/lobby/:id',
        builder: (_, s) => Scaffold(body: Text('Lobby ${s.pathParameters['id']}')),
      ),
    ]);

void main() {
  testWidgets('create flows through to the lobby route', (tester) async {
    final fake = _FakeRemote();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        matchServiceProvider.overrideWithValue(fake),
      ],
      child: MaterialApp.router(routerConfig: _router()),
    ));
    await tester.pump();
    await tester.tap(find.text('Create match'));
    await tester.pumpAndSettle();
    expect(fake.createdWith, 'medium');
    expect(find.text('Lobby m1'), findsOneWidget);
  });
}
