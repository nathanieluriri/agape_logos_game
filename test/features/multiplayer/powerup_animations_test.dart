import 'dart:async';

import 'package:agape_logos_game/features/auth/application/auth_providers.dart';
import 'package:agape_logos_game/features/auth/domain/auth_user.dart';
import 'package:agape_logos_game/features/multiplayer/application/match_providers.dart';
import 'package:agape_logos_game/features/multiplayer/data/match_remote.dart';
import 'package:agape_logos_game/features/multiplayer/domain/active_match.dart';
import 'package:agape_logos_game/features/multiplayer/domain/challenge_outcome.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match_event.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match_player.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match_rack.dart';
import 'package:agape_logos_game/features/multiplayer/domain/match_settings.dart';
import 'package:agape_logos_game/features/multiplayer/presentation/pages/match_page.dart';
import 'package:agape_logos_game/features/multiplayer/presentation/widgets/active_effect_chips.dart';
import 'package:agape_logos_game/features/multiplayer/presentation/widgets/powerup_incoming_banner.dart';
import 'package:agape_logos_game/features/puzzles/domain/puzzle.dart';
import 'package:agape_logos_game/features/store/application/store_providers.dart';
import 'package:agape_logos_game/features/store/domain/store_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRemote implements MatchRemote {
  @override
  Future<void> settle(String matchId) async {}
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
  Future<ChallengeOutcome> challenge(String toUid, {required String mode}) async =>
      const ChallengeSent('m1');
  @override
  Future<void> respondChallenge(String matchId, {required bool accept}) async {}
  @override
  Future<List<ActiveMatch>> activeMatches() async => const [];
}

MatchPlayer _p(String uid) => MatchPlayer(
      uid: uid, displayName: uid, avatarId: 'a', isGuest: false, ready: true,
      connected: true, score: 0, wordsFound: 0,
    );

Match _active() => Match(
      matchId: 'm1', code: 'ABCD', status: MatchStatus.active,
      participants: const ['me', 'opp'], playerOrder: const ['me', 'opp'],
      createdBy: 'me', createdAt: 0, startedAt: 0,
      endsAt: DateTime.now().millisecondsSinceEpoch + 90000,
      settings: MatchSettings.defaults(),
      players: {'me': _p('me'), 'opp': _p('opp')},
      winner: null,
    );

MatchRack _rack() => const MatchRack(
      uid: 'me', letters: ['I', 'F'], letterKey: 'FI', rackSize: 2,
      answers: [PuzzleAnswer(word: 'IF', length: 2, definition: null)],
      answerCount: 1, foundWords: [],
    );

void main() {
  group('PowerupIncomingBanner', () {
    testWidgets('shows caster name + powerup name and completes', (
      tester,
    ) async {
      var done = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PowerupIncomingBanner(
              data: const IncomingBannerData(
                casterName: 'Grace',
                powerupName: 'Fog Bank',
              ),
              onDone: () => done = true,
            ),
          ),
        ),
      );
      await tester.pump(); // drop-in starts
      await tester.pump(const Duration(milliseconds: 400)); // drop-in ends
      expect(find.text('Grace cast Fog Bank!'), findsOneWidget);
      expect(done, isFalse);

      // Holds for ~1500ms, then flies out over another ~320ms.
      await tester.pump(const Duration(milliseconds: 1600)); // hold elapses
      await tester.pump(const Duration(milliseconds: 400)); // fly-out ends
      expect(done, isTrue);
    });

    testWidgets('blocked variant shows the shield-shatter message', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PowerupIncomingBanner(
              data: const IncomingBannerData(
                casterName: 'Grace',
                powerupName: 'Fog Bank',
                blocked: true,
              ),
              onDone: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 320));
      expect(find.text('Shield blocked Fog Bank!'), findsOneWidget);
      expect(find.text('Grace cast Fog Bank!'), findsNothing);
    });
  });

  group('MatchPage event animation dedup', () {
    testWidgets('the same event id animates at most once', (tester) async {
      final events = StreamController<List<MatchEvent>>();
      addTearDown(events.close);
      final event = MatchEvent(
        id: 'e1',
        at: DateTime.now().millisecondsSinceEpoch,
        byUid: 'opp',
        targetUid: 'me',
        kind: MatchEventKind.fogBank,
        payload: const {},
        expiresAt: DateTime.now().millisecondsSinceEpoch + 8000,
      );

      await tester.pumpWidget(ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(const AuthUser(uid: 'me')),
          matchServiceProvider.overrideWithValue(_FakeRemote()),
          matchStreamProvider('m1')
              .overrideWith((ref) => Stream.value(_active())),
          myRackStreamProvider('m1')
              .overrideWith((ref) => Stream.value(_rack())),
          matchEventsStreamProvider('m1').overrideWith((ref) => events.stream),
          storeCatalogProvider.overrideWith((ref) async => const <StoreItem>[]),
        ],
        child: const MaterialApp(home: MatchPage(matchId: 'm1')),
      ));
      await tester.pump(); // match + rack streams emit
      await tester.pump(); // rack sync + rebuild

      // First emission: the banner appears.
      events.add([event]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400)); // drop-in done
      expect(find.byType(PowerupIncomingBanner), findsOneWidget);
      expect(find.textContaining('opp cast'), findsOneWidget);

      // A duplicate emission of the SAME event doc while the banner is still
      // up must not enqueue a second one.
      events.add([event]);
      await tester.pump();
      expect(find.byType(PowerupIncomingBanner), findsOneWidget);

      // Let the banner finish (drop-in + hold + fly-out; the ticker only
      // starts on the frame AFTER the banner enters the tree, so the whole
      // lifetime is pumped from here), then replay the event again: the
      // seen-set must keep it from re-animating.
      await tester.pump(const Duration(milliseconds: 400)); // drop-in
      await tester.pump(const Duration(milliseconds: 1600)); // hold
      await tester.pump(const Duration(milliseconds: 400)); // fly-out
      await tester.pump();
      expect(find.byType(PowerupIncomingBanner), findsNothing);

      events.add([event]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(PowerupIncomingBanner), findsNothing);
    });
  });

  group('ActiveEffectChips', () {
    const now = 10000;
    final effects = MatchActiveEffects(
      fog: true,
      fogUntil: DateTime.fromMillisecondsSinceEpoch(now + 4000),
      frozenLetter: 'A',
      freezeUntil: DateTime.fromMillisecondsSinceEpoch(now + 2500),
      doublePoints: true,
      warded: true,
      wardUntil: DateTime.fromMillisecondsSinceEpoch(now + 9000),
      shieldArmed: true,
    );

    testWidgets('renders remaining-seconds chips from a fake effects state', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActiveEffectChips(effects: effects, nowMillis: now),
          ),
        ),
      );

      expect(find.text('Fog 4s'), findsOneWidget);
      expect(find.text('Frozen 3s'), findsOneWidget); // ceil(2500ms) -> 3s
      expect(find.text('2x points'), findsOneWidget);
      expect(find.text('Warded 9s'), findsOneWidget);
      expect(find.text('Shield'), findsOneWidget);
    });

    testWidgets('renders nothing for an empty effects state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ActiveEffectChips(
              effects: MatchActiveEffects.empty,
              nowMillis: now,
            ),
          ),
        ),
      );
      expect(find.byType(Wrap), findsNothing);
    });

    testWidgets('drops a chip once its expiry has passed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActiveEffectChips(effects: effects, nowMillis: now + 5000),
          ),
        ),
      );
      // fog (until now+4000) and freeze (until now+2500) have both lapsed;
      // ward (until now+9000) and the armed-until-consumed shield have not.
      expect(find.textContaining('Fog'), findsNothing);
      expect(find.textContaining('Frozen'), findsNothing);
      expect(find.text('Shield'), findsOneWidget);
      expect(find.textContaining('Warded'), findsOneWidget);
    });
  });
}
