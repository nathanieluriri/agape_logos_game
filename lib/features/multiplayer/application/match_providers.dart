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

/// Contract 8.8: wraps the Cloud Function calls (create/join/ready/start/submit/
/// powerup/leave).
final matchServiceProvider = Provider<MatchRemote>(
  (ref) => HttpMatchRemote(ref.watch(apiClientProvider)),
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
final matchStreamProvider = StreamProvider.family<Match?, String>(
  (ref, matchId) => ref.watch(matchFirestoreProvider).watchMatch(matchId),
);

/// Contract 8.8: my private rack (answers decrypted). Empty stream when signed
/// out (multiplayer is auth-gated, so this only happens mid-sign-out).
final myRackStreamProvider =
    StreamProvider.family<MatchRack?, String>((ref, matchId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream<MatchRack?>.empty();
  return ref.watch(matchFirestoreProvider).watchMyRack(matchId, user.uid);
});

/// Contract 8.8: events targeting me (the raw incoming powerup stream).
final matchEventsStreamProvider =
    StreamProvider.family<List<MatchEvent>, String>((ref, matchId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const <MatchEvent>[]);
  return ref.watch(matchFirestoreProvider).watchEventsForMe(matchId, user.uid);
});

/// Derived live effects currently on me: which rack letter indices are frozen
/// (with their expiries) and the latest fog expiry. Pure projection: it re-emits
/// only when events change. The overlays own the wall-clock ticker that visually
/// expires an effect at its `expiresAt`, so this never has to tick.
class ActiveEffects {
  const ActiveEffects({required this.frozenLetters, required this.fogUntil});

  /// Rack letter index -> expiresAt (epoch millis).
  final Map<int, int> frozenLetters;

  /// Latest fog expiry (epoch millis), or null when no fog is live.
  final int? fogUntil;

  static const empty =
      ActiveEffects(frozenLetters: <int, int>{}, fogUntil: null);

  bool get hasFog => fogUntil != null;
}

/// Contract 8.8: `activeEffectsProvider(matchId)`.
final activeEffectsProvider =
    Provider.family<ActiveEffects, String>((ref, matchId) {
  final events =
      ref.watch(matchEventsStreamProvider(matchId)).value ?? const <MatchEvent>[];
  final now = DateTime.now().millisecondsSinceEpoch;
  final frozen = <int, int>{};
  int? fogUntil;
  for (final e in events) {
    if (e.expiresAt <= now) continue; // already lapsed at projection time
    if (e.kind == MatchEventKind.letterFreeze) {
      final idx = e.letterIndex;
      if (idx != null && (frozen[idx] == null || e.expiresAt > frozen[idx]!)) {
        frozen[idx] = e.expiresAt;
      }
    } else if (e.kind == MatchEventKind.fogBank) {
      if (fogUntil == null || e.expiresAt > fogUntil) fogUntil = e.expiresAt;
    }
  }
  return ActiveEffects(frozenLetters: frozen, fogUntil: fogUntil);
});
