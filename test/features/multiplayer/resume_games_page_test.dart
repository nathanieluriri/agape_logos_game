import 'package:agape_logos_game/features/multiplayer/application/match_providers.dart';
import 'package:agape_logos_game/features/multiplayer/application/resume_providers.dart';
import 'package:agape_logos_game/features/multiplayer/application/server_clock.dart';
import 'package:agape_logos_game/features/multiplayer/data/match_remote.dart';
import 'package:agape_logos_game/features/multiplayer/domain/active_match.dart';
import 'package:agape_logos_game/features/multiplayer/domain/challenge_invite.dart';
import 'package:agape_logos_game/features/multiplayer/domain/challenge_outcome.dart';
import 'package:agape_logos_game/features/multiplayer/presentation/pages/resume_games_page.dart';
import 'package:agape_logos_game/features/multiplayer/presentation/widgets/match_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// A [ServerClock] the test drives by hand instead of the wall clock, so the
/// `_GameTile` countdown (which now re-reads `serverClockProvider` every tick
/// per #32/#33) advances in lockstep with `tester.pump` rather than real time.
class _FakeServerClock extends ServerClock {
  _FakeServerClock(this._now);

  DateTime _now;

  @override
  DateTime now() => _now;

  void advance(Duration by) => _now = _now.add(by);
}

/// Advances both the fake clock and the widget-test clock together so a
/// `_GameTile` timer tick that fires mid-pump reads the post-advance time,
/// exactly like the real `ServerClock` would after elapsed wall time.
Future<void> _advanceClock(
  WidgetTester tester,
  _FakeServerClock clock,
  Duration by,
) async {
  clock.advance(by);
  await tester.pump(by);
}

/// Records the challenge responses the page fires.
class _FakeRemote implements MatchRemote {
  final List<({String matchId, bool accept})> responded = [];

  @override
  Future<void> respondChallenge(String matchId, {required bool accept}) async =>
      responded.add((matchId: matchId, accept: accept));

  @override
  Future<List<ActiveMatch>> activeMatches() async => const [];

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
  Future<PowerupFireResult> powerup(
    String m,
    String k, {
    required String eventId,
  }) async => (ok: true, reason: null);
  @override
  Future<void> leave(String matchId) async {}
  @override
  Future<void> settle(String matchId) async {}
  @override
  Future<ChallengeOutcome> challenge(String toUid, {required String mode}) async =>
      const ChallengeSent('m1');
}

ChallengeInvite _invite() => const ChallengeInvite(
      matchId: 'c1',
      byUid: 'u2',
      handle: 'grace',
      displayName: 'Grace',
      avatarId: 'a',
      mode: 'async',
      at: 1,
    );

ActiveMatch _match() => const ActiveMatch(
      matchId: 'm9',
      mode: 'async',
      status: 'active',
      opponentUid: 'u3',
      opponentName: 'Sam',
      myScore: 5,
      opponentScore: 2,
      startedAt: 0,
      endsAt: 0,
    );

Widget _host(_FakeRemote remote) {
  final router = GoRouter(
    initialLocation: '/multiplayer/resume',
    routes: [
      GoRoute(
        path: '/multiplayer/resume',
        builder: (_, __) => const ResumeGamesPage(),
      ),
      GoRoute(
        path: '/multiplayer/match/:id',
        builder: (_, s) => Text('Match ${s.pathParameters['id']}'),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      matchServiceProvider.overrideWithValue(remote),
      incomingChallengesProvider.overrideWith((ref) => Stream.value([_invite()])),
      activeMatchesProvider.overrideWith((ref) async => [_match()]),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

/// Hosts just the resume page with a controllable [activeMatchesProvider],
/// tracking how many times the underlying fetch actually runs so the tests
/// below can tell a refresh happened without needing a full [MatchRemote].
Widget _resumeHost({
  required List<ActiveMatch> Function() matches,
  required void Function() onFetch,
  required ServerClock clock,
}) {
  return ProviderScope(
    overrides: [
      incomingChallengesProvider.overrideWith(
        (ref) => const Stream<List<ChallengeInvite>>.empty(),
      ),
      activeMatchesProvider.overrideWith((ref) async {
        onFetch();
        return matches();
      }),
      serverClockProvider.overrideWithValue(clock),
    ],
    child: const MaterialApp(home: Scaffold(body: ResumeGamesPage())),
  );
}

Text _matchTimerText(WidgetTester tester) => tester.widget<Text>(
      find.descendant(
        of: find.byType(MatchTimer),
        matching: find.byType(Text),
      ),
    );

void main() {
  testWidgets('renders an incoming challenge and an active match row',
      (tester) async {
    await tester.pumpWidget(_host(_FakeRemote()));
    await tester.pumpAndSettle();

    expect(find.text('Grace challenged you'), findsOneWidget);
    expect(find.text('6-hour game'), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
    // The active match row.
    expect(find.text('Sam'), findsOneWidget);
    expect(find.text('5 - 2'), findsOneWidget);
  });

  testWidgets('tapping Accept calls respondChallenge(accept: true)',
      (tester) async {
    final remote = _FakeRemote();
    await tester.pumpWidget(_host(remote));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    expect(remote.responded, [(matchId: 'c1', accept: true)]);
  });

  testWidgets('the game tile reuses MatchTimer and its countdown ticks down',
      (tester) async {
    final clock = _FakeServerClock(DateTime.now());
    final endsAt = clock.now().millisecondsSinceEpoch + 5000;
    var fetches = 0;
    final match = ActiveMatch(
      matchId: 'm9',
      mode: 'async',
      status: 'active',
      opponentUid: 'u3',
      opponentName: 'Sam',
      myScore: 5,
      opponentScore: 2,
      startedAt: 0,
      endsAt: endsAt,
    );

    await tester.pumpWidget(
      _resumeHost(matches: () => [match], onFetch: () => fetches++, clock: clock),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(MatchTimer), findsOneWidget);
    final before = _matchTimerText(tester).data;

    await _advanceClock(tester, clock, const Duration(seconds: 2));
    final after = _matchTimerText(tester).data;

    // The shared widget is in use, and its label moved as time passed,
    // proving the tile ticks rather than showing a build-time snapshot.
    expect(after, isNot(equals(before)));
    // No expiry yet, so no refresh beyond the initial fetch.
    expect(fetches, 1);
  });

  testWidgets(
      'the game tile refreshes activeMatchesProvider once its countdown hits zero',
      (tester) async {
    final clock = _FakeServerClock(DateTime.now());
    final endsAt = clock.now().millisecondsSinceEpoch + 1500;
    var fetches = 0;
    final match = ActiveMatch(
      matchId: 'm9',
      mode: 'async',
      status: 'active',
      opponentUid: 'u3',
      opponentName: 'Sam',
      myScore: 5,
      opponentScore: 2,
      startedAt: 0,
      endsAt: endsAt,
    );

    await tester.pumpWidget(
      _resumeHost(matches: () => [match], onFetch: () => fetches++, clock: clock),
    );
    await tester.pump();
    await tester.pump();
    expect(fetches, 1);

    // Two 1s ticks cross the 1.5s deadline and fire the expiry refresh once.
    await _advanceClock(tester, clock, const Duration(seconds: 1));
    await _advanceClock(tester, clock, const Duration(seconds: 1));
    await tester.pump();

    expect(fetches, 2);

    // Further ticking must not refresh again (idempotent on the transition).
    await _advanceClock(tester, clock, const Duration(seconds: 1));
    expect(fetches, 2);
  });
}
