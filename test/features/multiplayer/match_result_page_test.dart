import 'package:agape_logos_game/features/auth/application/auth_providers.dart';
import 'package:agape_logos_game/features/auth/domain/auth_user.dart';
import 'package:agape_logos_game/features/multiplayer/application/match_providers.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match_player.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match_settings.dart';
import 'package:agape_logos_game/features/multiplayer/presentation/pages/match_result_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

MatchPlayer _p(String uid, int score) => MatchPlayer(
      uid: uid, displayName: uid, avatarId: 'a', isGuest: false, ready: true,
      connected: true, score: score, wordsFound: 0,
    );

Match _finished(String winner) => Match(
      matchId: 'm1', code: 'ABCD', status: MatchStatus.finished,
      participants: const ['me', 'opp'], playerOrder: const ['me', 'opp'],
      createdBy: 'me', createdAt: 0, startedAt: 0, endsAt: 0,
      settings: MatchSettings.defaults(),
      players: {'me': _p('me', 20), 'opp': _p('opp', 10)}, winner: winner,
    );

void main() {
  testWidgets('shows the win headline and both scores', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
        matchStreamProvider('m1')
            .overrideWith((ref) => Stream.value(_finished('me'))),
      ],
      child: const MaterialApp(home: MatchResultPage(matchId: 'm1')),
    ));
    await tester.pump();
    expect(find.text('You win'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('Rematch'), findsOneWidget);
  });
}
