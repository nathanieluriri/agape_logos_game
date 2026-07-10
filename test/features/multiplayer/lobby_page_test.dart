import 'package:agape_logos_game/features/auth/application/auth_providers.dart';
import 'package:agape_logos_game/features/auth/domain/auth_user.dart';
import 'package:agape_logos_game/features/multiplayer/application/match_providers.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match_player.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match_settings.dart';
import 'package:agape_logos_game/features/multiplayer/presentation/pages/lobby_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

MatchPlayer _p(String uid) => MatchPlayer(
      uid: uid, displayName: uid, avatarId: 'a', isGuest: false, ready: false,
      connected: true, score: 0, wordsFound: 0,
    );

Match _lobby() => Match(
      matchId: 'm1', code: 'ABCD', status: MatchStatus.lobby,
      participants: const ['me'], playerOrder: const ['me'], createdBy: 'me',
      createdAt: 0, startedAt: 0, endsAt: 0, settings: MatchSettings.defaults(),
      players: {'me': _p('me')}, winner: null,
    );

void main() {
  testWidgets('lobby shows the code and a ready action', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchStreamProvider('m1').overrideWith((ref) => Stream.value(_lobby())),
      ],
      child: const MaterialApp(home: LobbyPage(matchId: 'm1')),
    ));
    await tester.pump();
    expect(find.text('ABCD'), findsOneWidget);
    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('Waiting for an opponent to join...'), findsOneWidget);
  });
}
