import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firestore_providers.dart';
import '../../../core/network/network_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../../puzzles/application/puzzle_providers.dart';
import '../data/match_firestore.dart';
import '../data/match_remote.dart';
import '../domain/match.dart';
import '../domain/match_event.dart';
import '../domain/match_rack.dart';
import 'server_clock.dart';

/// One clock offset per app run: every powerup/settle response feeds it, and
/// every effect expiry check reads through it (contract update: server clock).
final serverClockProvider = Provider<ServerClock>((ref) => ServerClock());

/// Contract 8.8: wraps the Cloud Function calls (create/join/ready/start/submit/
/// powerup/leave).
final matchServiceProvider = Provider<MatchRemote>(
  (ref) => HttpMatchRemote(
    ref.watch(apiClientProvider),
    clock: ref.watch(serverClockProvider),
  ),
);

/// The Firestore read layer, sharing the puzzles' answer-key store so racks
/// decrypt with the same per-user key as single-player.
final matchFirestoreProvider = Provider<MatchFirestore>((ref) {
  final store = ref.watch(answerKeyStoreProvider);
  return MatchFirestore(
    ref.watch(firebaseFirestoreProvider),
    answerKey: () async {
      final user = ref.read(currentUserProvider);
      if (user == null) return null;
      return store.keyFor(user.uid);
    },
  );
});

/// Contract 8.8: the live match doc.
///
/// Auth-gated like the two listeners below. The rules deny an unauthenticated
/// read of the match doc, and a denied listener dies permanently: it never
/// retries once the user shows up. On web the persisted user is restored
/// asynchronously, so a page refresh straight onto a match route builds this
/// provider while `currentUser` is still null; attaching there is a guaranteed
/// permission-denied. Hold in `loading` until auth resolves, then attach.
/// Watching auth also means the listener re-attaches across a sign-in.
final matchStreamProvider = StreamProvider.family<Match?, String>((
  ref,
  matchId,
) {
  final auth = ref.watch(authStateProvider);
  // Still restoring the persisted user: not signed out, just not ready.
  if (auth.isLoading) return const Stream<Match?>.empty();
  final user = auth.value;
  if (user == null) {
    // Genuinely signed out. Surface it rather than spinning forever.
    return Stream<Match?>.error(
      StateError('Sign in to view this match.'),
      StackTrace.current,
    );
  }
  return ref.watch(matchFirestoreProvider).watchMatch(matchId);
});

/// Contract 8.8: my private rack (answers decrypted). Empty stream when signed
/// out (multiplayer is auth-gated, so this only happens mid-sign-out).
final myRackStreamProvider = StreamProvider.family<MatchRack?, String>((
  ref,
  matchId,
) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream<MatchRack?>.empty();
  return ref.watch(matchFirestoreProvider).watchMyRack(matchId, user.uid);
});

/// Contract 8.8: events targeting me (the raw incoming powerup stream).
final matchEventsStreamProvider =
    StreamProvider.family<List<MatchEvent>, String>((ref, matchId) {
      final user = ref.watch(currentUserProvider);
      if (user == null) return Stream.value(const <MatchEvent>[]);
      return ref
          .watch(matchFirestoreProvider)
          .watchEventsForMe(matchId, user.uid);
    });

/// How long a `warded` flash stays true after it lands. Events are the
/// animation feed (no persisted "warded" state exists), so this projection
/// treats a recent warded event as a short-lived flag rather than ticking a
/// stateful timer.
const Duration kWardedFlashWindow = Duration(seconds: 3);

/// Derived live effects currently on me, sourced from the match doc's
/// server-persisted `activeEffects` (never from the events feed, which stays
/// the animation-only channel). Expiry is checked against [ServerClock.now],
/// so a skewed device clock never mis-times an expiry.
class MatchActiveEffects {
  const MatchActiveEffects({
    this.fog = false,
    this.frozenLetterCp,
    this.frozenLetter,
    this.fogUntil,
    this.freezeUntil,
    this.doublePoints = false,
    this.warded = false,
    this.shieldArmed = false,
  });

  final bool fog;

  /// Unicode code point of the frozen character, for the wheel painter.
  final int? frozenLetterCp;
  final String? frozenLetter;
  final DateTime? fogUntil;
  final DateTime? freezeUntil;
  final bool doublePoints;
  final bool warded;
  final bool shieldArmed;

  static const empty = MatchActiveEffects();
}

/// Contract 8.8: `activeEffectsProvider(matchId)`. Reads MY entries out of the
/// match doc `activeEffects` map, not the events stream; `warded` is the one
/// exception since a ward never lands in `activeEffects` (it is a moment, not
/// a state).
final activeEffectsProvider = Provider.family<MatchActiveEffects, String>((
  ref,
  matchId,
) {
  final uid = ref.watch(currentUserProvider)?.uid;
  final match = ref.watch(matchStreamProvider(matchId)).value;
  if (uid == null || match == null) return MatchActiveEffects.empty;

  final clock = ref.watch(serverClockProvider);
  final now = clock.now();
  final nowMs = now.millisecondsSinceEpoch;

  var fog = false;
  DateTime? fogUntil;
  String? frozenLetter;
  int? frozenLetterCp;
  DateTime? freezeUntil;
  var doublePoints = false;
  var shieldArmed = false;

  for (final e in match.effectsFor(uid, nowMs: nowMs)) {
    final expiresAt = e.armedUntilConsumed
        ? null
        : DateTime.fromMillisecondsSinceEpoch(e.expiresAt);
    switch (e.kind) {
      case MatchEffectKind.fogBank:
        fog = true;
        if (expiresAt != null &&
            (fogUntil == null || expiresAt.isAfter(fogUntil))) {
          fogUntil = expiresAt;
        }
        break;
      case MatchEffectKind.letterFreeze:
        final letter = e.frozenLetter;
        if (letter != null && letter.isNotEmpty) {
          frozenLetter = letter;
          frozenLetterCp = letter.runes.first;
          if (expiresAt != null &&
              (freezeUntil == null || expiresAt.isAfter(freezeUntil))) {
            freezeUntil = expiresAt;
          }
        }
        break;
      case MatchEffectKind.doublePoints:
        doublePoints = true;
        break;
      case MatchEffectKind.shield:
        if (e.armedUntilConsumed) shieldArmed = true;
        break;
      case MatchEffectKind.comboLock:
      case MatchEffectKind.unknown:
        break;
    }
  }

  final events =
      ref.watch(matchEventsStreamProvider(matchId)).value ??
      const <MatchEvent>[];
  final warded = events.any(
    (e) =>
        e.kind == MatchEventKind.warded &&
        !now.isBefore(DateTime.fromMillisecondsSinceEpoch(e.at)) &&
        now.difference(DateTime.fromMillisecondsSinceEpoch(e.at)) <
            kWardedFlashWindow,
  );

  return MatchActiveEffects(
    fog: fog,
    frozenLetterCp: frozenLetterCp,
    frozenLetter: frozenLetter,
    fogUntil: fogUntil,
    freezeUntil: freezeUntil,
    doublePoints: doublePoints,
    warded: warded,
    shieldArmed: shieldArmed,
  );
});

/// My effective deadline right now: `endsAt` plus my banked time_boost bonus.
final matchDeadlineProvider = Provider.family<int?, String>((ref, matchId) {
  final uid = ref.watch(currentUserProvider)?.uid;
  final match = ref.watch(matchStreamProvider(matchId)).value;
  if (uid == null || match == null) return null;
  return match.deadlineFor(uid);
});
