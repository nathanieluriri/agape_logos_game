import 'dart:async';

import 'package:agape_logos_game/core/haptics/haptic_service.dart';
import 'package:agape_logos_game/core/haptics/haptics.dart';
import 'package:agape_logos_game/features/auth/application/auth_providers.dart';
import 'package:agape_logos_game/features/auth/domain/auth_user.dart';
import 'package:agape_logos_game/features/game/presentation/widgets/formed_word_pill.dart';
import 'package:agape_logos_game/features/game/presentation/widgets/letter_wheel.dart';
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

/// Records which haptic calls fired, so a test can assert the incoming-attack
/// buzz (heavyImpact) never fires for a self-cast event.
class _RecordingHaptics implements HapticService {
  final calls = <String>[];
  @override
  Future<void> init() async {}
  @override
  Future<void> lightImpact() async => calls.add('light');
  @override
  Future<void> mediumImpact() async => calls.add('medium');
  @override
  Future<void> heavyImpact() async => calls.add('heavy');
  @override
  Future<void> gameImpact() async => calls.add('game');
  @override
  Future<void> streakImpact() async => calls.add('streak');
  @override
  Future<void> mistakeImpact() async => calls.add('mistake');
  @override
  Future<void> selectionClick() async => calls.add('selection');
  @override
  Future<void> successPattern() async => calls.add('success');
  @override
  Future<void> tickImpact() async => calls.add('tick');
  @override
  void setMuted(bool muted) {}
}

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

      // The very first stream emission (an empty snapshot, standing in for
      // "nothing pending on mount") is seeded, not animated.
      events.add(const []);
      await tester.pump();
      expect(find.byType(PowerupIncomingBanner), findsNothing);

      // A genuinely new event, emitted AFTER the first snapshot: it animates.
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

    testWidgets(
      'events present in the initial stream emission do not animate '
      '(async resume replays history without a banner storm)',
      (tester) async {
        final events = StreamController<List<MatchEvent>>();
        addTearDown(events.close);
        final historical = List.generate(
          3,
          (i) => MatchEvent(
            id: 'old-$i',
            at: DateTime.now().millisecondsSinceEpoch - 60000,
            byUid: 'opp',
            targetUid: 'me',
            kind: MatchEventKind.fogBank,
            payload: const {},
            expiresAt: DateTime.now().millisecondsSinceEpoch - 50000,
          ),
        );
        final fresh = MatchEvent(
          id: 'new-1',
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
            matchEventsStreamProvider('m1')
                .overrideWith((ref) => events.stream),
            storeCatalogProvider.overrideWith((ref) async => const <StoreItem>[]),
          ],
          child: const MaterialApp(home: MatchPage(matchId: 'm1')),
        ));
        await tester.pump();
        await tester.pump();

        // Re-entering an async match replays every historical event targeting
        // me as the first snapshot: none of these must animate a banner.
        events.add(historical);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(PowerupIncomingBanner), findsNothing);

        // A genuinely new event fired after that first snapshot still
        // animates normally.
        events.add([...historical, fresh]);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(PowerupIncomingBanner), findsOneWidget);
      },
    );

    // Regression: the events stream is a doc-query replay (every emission
    // repeats ALL historical events, not just new ones). A scramble that has
    // already been applied must not re-arm the wheel's 900ms swirl a second
    // time, or an unrelated re-emission would relock the wheel's input for
    // the rest of the match.
    testWidgets(
      'a replayed scramble event does not re-arm the wheel swirl',
      (tester) async {
        final events = StreamController<List<MatchEvent>>();
        addTearDown(events.close);
        final scramble = MatchEvent(
          id: 's1',
          at: DateTime.now().millisecondsSinceEpoch,
          byUid: 'opp',
          targetUid: 'me',
          kind: MatchEventKind.scramble,
          payload: const {},
          expiresAt: 0,
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

        // Seed: the first snapshot is historical, not new.
        events.add(const []);
        await tester.pump();

        // A genuinely new scramble: arms the wheel's 900ms swirl from here.
        events.add([scramble]);
        await tester.pump();

        // Mid-flight: halfway through the swirl.
        await tester.pump(const Duration(milliseconds: 500));

        // The doc query re-emits the SAME event (a Firestore snapshot
        // replay, e.g. from an unrelated field changing). The buggy version
        // re-armed the swirl on every such replay, pushing completion out
        // another 900ms from THIS point and leaving the wheel permanently
        // locked; the fix recognizes the id as already-seen and leaves the
        // in-flight swirl alone.
        events.add([scramble]);
        await tester.pump();

        // Past the ORIGINAL completion (900ms after the first, genuine arm).
        // Fixed: the swirl has settled and the wheel accepts input again.
        // Buggy: the replay pushed completion to 1400ms, so a drag here
        // would still be ignored and the formed-word pill would stay empty.
        await tester.pump(const Duration(milliseconds: 450));

        final wheelFinder = find.byType(LetterWheel);
        final wheelTopLeft = tester.getTopLeft(wheelFinder);
        final wheelSize = tester.getSize(wheelFinder);
        // Slot 0 (12 o'clock) on the 2-letter rack, in the wheel's actual
        // on-screen geometry (the FittedBox around it may scale it down).
        final slot0 = wheelTopLeft + LetterWheel.centersIn(wheelSize, 2)[0];

        final gesture = await tester.startGesture(slot0);
        await gesture.moveBy(const Offset(6, 6));
        await tester.pump();

        expect(
          find.descendant(
            of: find.byType(FormedWordPill),
            matching: find.byType(Text),
          ),
          findsWidgets,
        );

        await gesture.up();
        await tester.pump();
      },
    );

    // Regression: same doc-query replay hazard as the scramble case above,
    // but for word_steal. `ctrl.applyWordSteal` already dedupes the rack
    // side effect internally; this pins down that the VISUAL flyout also
    // fires at most once per event id, not once per stream emission.
    testWidgets(
      'a replayed word-steal event does not re-fire the flyout',
      (tester) async {
        final events = StreamController<List<MatchEvent>>();
        addTearDown(events.close);
        final steal = MatchEvent(
          id: 'w1',
          at: DateTime.now().millisecondsSinceEpoch,
          byUid: 'opp',
          targetUid: 'me',
          kind: MatchEventKind.wordSteal,
          payload: const {'word': 'lotus'},
          expiresAt: 0,
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

        // Seed: the first snapshot is historical, not new.
        events.add(const []);
        await tester.pump();

        // A genuinely new steal: fires the flyout.
        events.add([steal]);
        await tester.pump();
        expect(find.text('LOTUS'), findsOneWidget);

        // The doc query re-emits the SAME event while the first flyout is
        // still mid-flight. A second flyout stacked on top would still read
        // as one 'LOTUS' text via findsOneWidget below only if the dedup
        // gate held; the buggy version inserts a second overlay entry here.
        events.add([steal]);
        await tester.pump();
        expect(find.text('LOTUS'), findsOneWidget);

        // Let the flyout finish (AppDurations.stealFlight = 800ms); it
        // self-removes.
        await tester.pump(const Duration(milliseconds: 800));
        await tester.pumpAndSettle();
        expect(find.text('LOTUS'), findsNothing);
      },
    );
  });

  group('MatchPage self-cast suppression (#45)', () {
    late _RecordingHaptics haptics;
    late HapticService previousHaptics;

    setUp(() {
      previousHaptics = Haptics.instance;
      haptics = _RecordingHaptics();
      Haptics.instance = haptics;
    });
    tearDown(() => Haptics.instance = previousHaptics);

    // Self-target powerups (shield, double_points, combo_lock, time_boost) are
    // written server-side with targetUid == the caster, so casting one on
    // yourself reaches `watchEventsForMe` with byUid == myUid too. Before the
    // fix, the client's enum has no case for these wire kinds so they mapped
    // to `unknown`, whose non-empty wire string slipped past the
    // `wireKind.isEmpty` guard and queued a false "you got hit" banner
    // (labeled "unknown") with the incoming SFX and a heavy haptic buzz.
    testWidgets(
      'casting a self-buff does not queue the incoming banner or heavy haptic',
      (tester) async {
        final events = StreamController<List<MatchEvent>>();
        addTearDown(events.close);
        final selfBuff = MatchEvent(
          id: 'self-1',
          at: DateTime.now().millisecondsSinceEpoch,
          byUid: 'me',
          targetUid: 'me',
          kind: MatchEventKind.unknown, // shield/double_points/etc: no case
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

        // Seed: the first snapshot is historical, not new.
        events.add(const []);
        await tester.pump();

        // The self-cast buff arrives as a genuinely new event.
        events.add([selfBuff]);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400)); // drop-in window

        expect(find.byType(PowerupIncomingBanner), findsNothing);
        expect(find.textContaining('cast'), findsNothing);
        expect(haptics.calls, isNot(contains('heavy')));
      },
    );

    // Control: the opponent's OWN offensive cast (byUid == opponent, targeting
    // me) must be entirely unaffected by the self-cast suppression above.
    testWidgets(
      "an opponent's offensive cast still shows the incoming banner and buzzes",
      (tester) async {
        final events = StreamController<List<MatchEvent>>();
        addTearDown(events.close);
        final opponentAttack = MatchEvent(
          id: 'opp-1',
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
        await tester.pump();
        await tester.pump();

        events.add(const []);
        await tester.pump();

        events.add([opponentAttack]);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.byType(PowerupIncomingBanner), findsOneWidget);
        expect(find.textContaining('opp cast'), findsOneWidget);
        expect(haptics.calls, contains('heavy'));
      },
    );
  });

  group('ActiveEffectChips', () {
    const now = 10000;
    final effects = MatchActiveEffects(
      fog: true,
      fogUntil: DateTime.fromMillisecondsSinceEpoch(now + 4000),
      frozenLetter: 'A',
      freezeUntil: DateTime.fromMillisecondsSinceEpoch(now + 2500),
      doublePoints: true,
      doublePointsUntil: DateTime.fromMillisecondsSinceEpoch(now + 6000),
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
      expect(find.text('2x points 6s'), findsOneWidget);
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
      // fog (until now+4000), freeze (until now+2500) have both lapsed; ward
      // (until now+9000), double points (until now+6000), and the
      // armed-until-consumed shield have not.
      expect(find.textContaining('Fog'), findsNothing);
      expect(find.textContaining('Frozen'), findsNothing);
      expect(find.text('Shield'), findsOneWidget);
      expect(find.textContaining('Warded'), findsOneWidget);
      expect(find.textContaining('2x points'), findsOneWidget);
    });
  });
}
