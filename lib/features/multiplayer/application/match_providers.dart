import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firestore_providers.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/storage/storage_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../../puzzles/application/puzzle_providers.dart';
import '../data/match_firestore.dart';
import '../data/match_leave_repository.dart';
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

/// Durable-queue path for a forfeit: a leave routed through the offline sync
/// engine (with backoff + a stable idempotency key) so it survives an offline
/// exit instead of vanishing as a bare fire-and-forget call. See issue #38.
final matchLeaveRepositoryProvider = Provider<MatchLeaveRepository>(
  (ref) => MatchLeaveRepository(ref.watch(appDatabaseProvider)),
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

/// Derived live effects currently on me, sourced from the match doc's
/// server-persisted `activeEffects` (never from the events feed, which stays
/// the animation-only channel). Expiry is checked against [ServerClock.now],
/// so a skewed device clock never mis-times an expiry.
class MatchActiveEffects {
  const MatchActiveEffects({
    this.fog = false,
    this.frozenLetterExpiries = const {},
    this.fogUntil,
    this.freezeUntil,
    this.doublePoints = false,
    this.doublePointsUntil,
    this.warded = false,
    this.wardUntil,
    this.shieldArmed = false,
    this.fogStacks = 0,
    this.freezeStacks = 0,
    this.doublePointsStacks = 0,
    this.wardStacks = 0,
    this.shieldCharges = 0,
  });

  final bool fog;

  /// Every currently-frozen letter mapped to its OWN expiry (latest wins if
  /// the same letter gets frozen twice). A stacked cast (opponent casts
  /// letter_freeze twice within the no-cooldown window, landing E then R)
  /// leaves BOTH letters here, mirroring the server's submit validator,
  /// which rejects a word containing ANY active freeze letter (issue #54).
  /// Checked against a ticking clock (not just recomputed on a fresh
  /// Firestore snapshot) so a letter drops out of the frozen set the instant
  /// its own window ends, same as the old single-letter [freezeUntil] did.
  final Map<String, DateTime> frozenLetterExpiries;

  /// The set of currently-frozen letters (raw casing from the server).
  Set<String> get frozenLetters => frozenLetterExpiries.keys.toSet();

  final DateTime? fogUntil;

  /// Latest expiry across ALL active freeze entries (used only for the
  /// group countdown chip; per-letter expiry lives in
  /// [frozenLetterExpiries]).
  final DateTime? freezeUntil;
  final bool doublePoints;

  /// Expiry of the double_points effect. The chip ticks against this (like
  /// fog/freeze/ward) instead of persisting until the next Firestore doc
  /// change re-evaluates the bare [doublePoints] flag.
  final DateTime? doublePointsUntil;

  /// A combo_lock ward is live on me right now (persisted match-doc state, so
  /// a reconnecting player mid-ward still sees it).
  final bool warded;
  final DateTime? wardUntil;
  final bool shieldArmed;

  /// Live entry counts per kind, so stacked casts (Project B) render as
  /// intensity. A live effect implies its count is >= 1; 0 means not active.
  final int fogStacks;
  final int freezeStacks;
  final int doublePointsStacks;
  final int wardStacks;

  /// Number of armed-until-consumed shields.
  final int shieldCharges;

  static const empty = MatchActiveEffects();
}

/// Contract 8.8: `activeEffectsProvider(matchId)`. Reads MY entries out of the
/// match doc `activeEffects` map, not the events stream (which stays the
/// animation-only channel). `warded` is the persisted combo_lock ward, so a
/// reconnecting player mid-ward still sees it.
final activeEffectsProvider = Provider.family<MatchActiveEffects, String>((
  ref,
  matchId,
) {
  final uid = ref.watch(currentUserProvider)?.uid;
  final match = ref.watch(matchStreamProvider(matchId)).value;
  if (uid == null || match == null) return MatchActiveEffects.empty;

  final clock = ref.watch(serverClockProvider);
  final nowMs = clock.now().millisecondsSinceEpoch;

  var fog = false;
  DateTime? fogUntil;
  final frozenLetterExpiries = <String, DateTime>{};
  DateTime? freezeUntil;
  var doublePoints = false;
  DateTime? doublePointsUntil;
  var warded = false;
  DateTime? wardUntil;
  var shieldArmed = false;
  var fogCount = 0;
  var freezeCount = 0;
  var doubleCount = 0;
  var wardCount = 0;
  var shieldCount = 0;

  for (final e in match.effectsFor(uid, nowMs: nowMs)) {
    final expiresAt = e.armedUntilConsumed
        ? null
        : DateTime.fromMillisecondsSinceEpoch(e.expiresAt);
    switch (e.kind) {
      case MatchEffectKind.fogBank:
        fog = true;
        fogCount++;
        if (expiresAt != null &&
            (fogUntil == null || expiresAt.isAfter(fogUntil))) {
          fogUntil = expiresAt;
        }
        break;
      case MatchEffectKind.letterFreeze:
        final letter = e.frozenLetter;
        if (letter != null && letter.isNotEmpty) {
          freezeCount++;
          if (expiresAt != null) {
            final existing = frozenLetterExpiries[letter];
            if (existing == null || expiresAt.isAfter(existing)) {
              frozenLetterExpiries[letter] = expiresAt;
            }
            if (freezeUntil == null || expiresAt.isAfter(freezeUntil)) {
              freezeUntil = expiresAt;
            }
          }
        }
        break;
      case MatchEffectKind.doublePoints:
        doublePoints = true;
        doubleCount++;
        if (expiresAt != null &&
            (doublePointsUntil == null ||
                expiresAt.isAfter(doublePointsUntil))) {
          doublePointsUntil = expiresAt;
        }
        break;
      case MatchEffectKind.shield:
        if (e.armedUntilConsumed) {
          shieldArmed = true;
          shieldCount++;
        }
        break;
      case MatchEffectKind.comboLock:
        warded = true;
        wardCount++;
        if (expiresAt != null &&
            (wardUntil == null || expiresAt.isAfter(wardUntil))) {
          wardUntil = expiresAt;
        }
        break;
      case MatchEffectKind.unknown:
        break;
    }
  }

  return MatchActiveEffects(
    fog: fog,
    frozenLetterExpiries: frozenLetterExpiries,
    fogUntil: fogUntil,
    freezeUntil: freezeUntil,
    doublePoints: doublePoints,
    doublePointsUntil: doublePointsUntil,
    warded: warded,
    wardUntil: wardUntil,
    shieldArmed: shieldArmed,
    fogStacks: fogCount,
    freezeStacks: freezeCount,
    doublePointsStacks: doubleCount,
    wardStacks: wardCount,
    shieldCharges: shieldCount,
  );
});

/// My effective deadline right now: `endsAt` plus my banked time_boost bonus.
final matchDeadlineProvider = Provider.family<int?, String>((ref, matchId) {
  final uid = ref.watch(currentUserProvider)?.uid;
  final match = ref.watch(matchStreamProvider(matchId)).value;
  if (uid == null || match == null) return null;
  return match.deadlineFor(uid);
});
