import 'package:freezed_annotation/freezed_annotation.dart';

import 'match_player.dart';
import 'match_settings.dart';

part 'match.freezed.dart';

enum MatchStatus { lobby, countdown, active, finished, cancelled }

/// Kinds the server persists into the match doc's `activeEffects` (contract
/// update: server clock + activeEffects). Distinct from [MatchEventKind],
/// which is the append-only animation feed; this is durable STATE.
enum MatchEffectKind {
  letterFreeze,
  fogBank,
  doublePoints,
  comboLock,
  shield,
  unknown,
}

MatchEffectKind matchEffectKindFromWire(String? raw) {
  switch (raw) {
    case 'letter_freeze':
      return MatchEffectKind.letterFreeze;
    case 'fog_bank':
      return MatchEffectKind.fogBank;
    case 'double_points':
      return MatchEffectKind.doublePoints;
    case 'combo_lock':
      return MatchEffectKind.comboLock;
    case 'shield':
      return MatchEffectKind.shield;
    default:
      return MatchEffectKind.unknown;
  }
}

/// One entry of `activeEffects[uid]` (contract update). `expiresAt == 0` means
/// armed-until-consumed (shield) rather than time-bounded.
@freezed
abstract class MatchActiveEffect with _$MatchActiveEffect {
  const factory MatchActiveEffect({
    required MatchEffectKind kind,
    required String byUid,
    required int startedAt,
    required int expiresAt,
    required Map<String, dynamic> payload,
  }) = _MatchActiveEffect;

  const MatchActiveEffect._();

  /// `letter_freeze` payload: the frozen CHARACTER (freezes every wheel slot
  /// showing it, so it stays valid across a shuffle).
  String? get frozenLetter => payload['letter'] as String?;

  /// Armed until consumed rather than time-bounded (shield).
  bool get armedUntilConsumed => expiresAt == 0;
}

MatchStatus matchStatusFromWire(String? raw) {
  switch (raw) {
    case 'countdown':
      return MatchStatus.countdown;
    case 'active':
      return MatchStatus.active;
    case 'finished':
      return MatchStatus.finished;
    case 'cancelled':
      return MatchStatus.cancelled;
    default:
      return MatchStatus.lobby;
  }
}

/// The shared, participant-scoped match document (contract 8.2). Read-only on
/// the client (rules forbid client writes); every change comes from a Cloud
/// Function via the Firestore listener.
@freezed
abstract class Match with _$Match {
  const factory Match({
    required String matchId,
    required String code,
    required MatchStatus status,
    required List<String> participants,
    required List<String> playerOrder,
    required String createdBy,
    required int createdAt,
    required int startedAt,
    required int endsAt,
    required MatchSettings settings,
    required Map<String, MatchPlayer> players,
    String? winner,
    String? puzzleId,
    @Default(<String, List<MatchActiveEffect>>{})
    Map<String, List<MatchActiveEffect>> activeEffects,
  }) = _Match;

  const Match._();

  MatchPlayer? playerFor(String uid) => players[uid];

  /// Live (not-yet-lapsed at `nowMs`) effects on [uid], sourced from the
  /// server-persisted `activeEffects` doc, never from the events feed.
  List<MatchActiveEffect> effectsFor(String uid, {int? nowMs}) {
    final all = activeEffects[uid] ?? const <MatchActiveEffect>[];
    if (nowMs == null) return all;
    return all
        .where((e) => e.armedUntilConsumed || e.expiresAt > nowMs)
        .toList();
  }

  /// My effective deadline: `endsAt` plus any time_boost bonus banked on my
  /// player record.
  int deadlineFor(String uid) => endsAt + (players[uid]?.endsAtBonusMs ?? 0);

  /// The other participant (v1 is 1v1, so the first player whose uid is not
  /// [uid]); null while the lobby is still waiting for an opponent.
  MatchPlayer? opponentOf(String uid) {
    for (final entry in players.entries) {
      if (entry.key != uid) return entry.value;
    }
    return null;
  }

  bool isCreator(String uid) => createdBy == uid;

  bool get hasOpponent => players.length >= 2;

  bool get bothReady =>
      players.length == 2 && players.values.every((p) => p.ready);

  /// Play is CLOCK-driven, not status-driven. `start` sets `startedAt` a few
  /// seconds out and parks the doc in `countdown`; the server only flips it to
  /// `active` inside `settleMatch`, which runs on the next submit/powerup. So
  /// waiting for `status == active` to open the board deadlocks the match: every
  /// call that would settle it is gated behind the board it is gating. Both
  /// clients therefore open the board at `startedAt` (the shared "go" instant the
  /// countdown exists to agree on), and the first submit settles the doc for
  /// everyone.
  bool playableAt(int nowMs) {
    if (endsAt > 0 && nowMs >= endsAt) return false;
    // The server has declared it active: trust that, whatever the local clock says.
    if (status == MatchStatus.active) {
      return startedAt <= 0 || nowMs >= startedAt;
    }
    // Not yet settled: open the board at the shared start instant anyway.
    return status == MatchStatus.countdown &&
        startedAt > 0 &&
        nowMs >= startedAt;
  }

  /// Like [playableAt], but against [uid]'s effective deadline (`endsAt` plus
  /// their banked time_boost bonus). Raw `endsAt` would strand a boosted
  /// player on the timeout screen while their personal clock still runs.
  bool playableFor(String uid, int nowMs) {
    if (endsAt > 0 && nowMs >= deadlineFor(uid)) return false;
    if (status == MatchStatus.active) {
      return startedAt <= 0 || nowMs >= startedAt;
    }
    return status == MatchStatus.countdown &&
        startedAt > 0 &&
        nowMs >= startedAt;
  }

  /// Still counting down to the shared start instant.
  bool countingDownAt(int nowMs) =>
      status == MatchStatus.countdown && startedAt > 0 && nowMs < startedAt;

  /// Whole seconds left on the pre-start countdown (0 once it has started).
  int countdownSecondsAt(int nowMs) {
    final remaining = startedAt - nowMs;
    return remaining <= 0 ? 0 : (remaining / 1000).ceil();
  }
}
