import 'package:freezed_annotation/freezed_annotation.dart';

part 'match_event.freezed.dart';

/// Powerup/effect kinds (contract 8.5). `blocked` and `warded` are animation-
/// only events fired when a shield absorbs an incoming offensive effect (the
/// target sees `warded`, the caster's blocked attempt is `blocked` with
/// `payload.originalKind`). `unknown` guards forward compatibility.
enum MatchEventKind {
  letterFreeze,
  fogBank,
  scramble,
  wordSteal,
  blocked,
  warded,
  unknown,
}

MatchEventKind matchEventKindFromWire(String raw) {
  switch (raw) {
    case 'letter_freeze':
      return MatchEventKind.letterFreeze;
    case 'fog_bank':
      return MatchEventKind.fogBank;
    case 'scramble':
      return MatchEventKind.scramble;
    case 'word_steal':
      return MatchEventKind.wordSteal;
    case 'blocked':
      return MatchEventKind.blocked;
    case 'warded':
      return MatchEventKind.warded;
    default:
      return MatchEventKind.unknown;
  }
}

String matchEventKindToWire(MatchEventKind kind) {
  switch (kind) {
    case MatchEventKind.letterFreeze:
      return 'letter_freeze';
    case MatchEventKind.fogBank:
      return 'fog_bank';
    case MatchEventKind.scramble:
      return 'scramble';
    case MatchEventKind.wordSteal:
      return 'word_steal';
    case MatchEventKind.blocked:
      return 'blocked';
    case MatchEventKind.warded:
      return 'warded';
    case MatchEventKind.unknown:
      return 'unknown';
  }
}

/// An append-only powerup/effect event targeting one player (contract 8.4). The
/// target's client reacts: freeze a wheel node, blur the board, reshuffle, or
/// drop a stolen word. `expiresAt` (epoch millis, 0 for instant effects) makes
/// both sides agree on timing.
@freezed
abstract class MatchEvent with _$MatchEvent {
  const factory MatchEvent({
    required String id,
    required int at,
    required String byUid,
    required String targetUid,
    required MatchEventKind kind,
    required Map<String, dynamic> payload,
    required int expiresAt,
  }) = _MatchEvent;

  const MatchEvent._();

  /// `letter_freeze` payload: which rack letter index is locked. Superseded by
  /// [frozenLetter] (the server now freezes by character, not slot index), kept
  /// for any event still carrying the legacy shape.
  int? get letterIndex => (payload['letterIndex'] as num?)?.toInt();

  /// `letter_freeze` payload: the CHARACTER that is frozen wherever it appears
  /// on the wheel (shuffle-safe, unlike a fixed slot index).
  String? get frozenLetter => payload['letter'] as String?;

  /// `blocked` payload: the offensive kind a shield absorbed.
  String? get originalKind => payload['originalKind'] as String?;

  /// `word_steal` payload: the word taken and the points transferred.
  String? get stolenWord => payload['word'] as String?;
  int get stolenPoints => (payload['points'] as num?)?.toInt() ?? 0;

  bool activeAt(int nowMillis) => expiresAt > nowMillis;
}
