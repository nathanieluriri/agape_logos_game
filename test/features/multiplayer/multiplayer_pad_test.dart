import 'package:agape_logos_game/features/multiplayer/application/resume_providers.dart';
import 'package:agape_logos_game/features/multiplayer/domain/active_match.dart';
import 'package:agape_logos_game/features/multiplayer/domain/challenge_invite.dart';
import 'package:agape_logos_game/features/multiplayer/presentation/widgets/multiplayer_pad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The pad is a ConsumerWidget (it watches the same challenge + active-match
  // providers as the "Play with friends" sheet's Resume badge), so it needs a
  // ProviderScope. The overrides keep those providers off the network.
  Widget host({
    List<ChallengeInvite> challenges = const [],
    List<ActiveMatch> matches = const [],
  }) =>
      ProviderScope(
        overrides: [
          incomingChallengesProvider.overrideWith((ref) => Stream.value(challenges)),
          activeMatchesProvider.overrideWith((ref) async => matches),
        ],
        child: const MaterialApp(
          home: Scaffold(body: Center(child: MultiplayerPad())),
        ),
      );

  testWidgets('multiplayer pad renders the Versus affordance', (tester) async {
    await tester.pumpWidget(host());
    await tester.pump();
    expect(find.text('Versus'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Versus, play a friend'),
      findsOneWidget,
    );
  });

  testWidgets('shows no badge when there are no pending matches', (tester) async {
    await tester.pumpWidget(host());
    await tester.pump();
    expect(find.text('0'), findsNothing);
    expect(
      find.bySemanticsLabel('Versus, play a friend'),
      findsOneWidget,
    );
  });

  testWidgets(
    'shows the combined active-matches + incoming-challenges count as a badge',
    (tester) async {
      await tester.pumpWidget(
        host(
          challenges: const [
            ChallengeInvite(
              matchId: 'm1',
              byUid: 'u1',
              handle: 'ada',
              displayName: 'Ada',
              avatarId: 'frog',
              mode: 'live',
              at: 0,
            ),
          ],
          matches: const [
            ActiveMatch(
              matchId: 'm2',
              mode: 'live',
              status: 'active',
              opponentUid: 'u2',
              opponentName: 'Bea',
              myScore: 0,
              opponentScore: 0,
              startedAt: 0,
              endsAt: 0,
            ),
            ActiveMatch(
              matchId: 'm3',
              mode: 'live',
              status: 'active',
              opponentUid: 'u3',
              opponentName: 'Cai',
              myScore: 0,
              opponentScore: 0,
              startedAt: 0,
              endsAt: 0,
            ),
          ],
        ),
      );
      await tester.pump();
      expect(find.text('3'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Versus, play a friend, 3 to resume'),
        findsOneWidget,
      );
    },
  );
}
