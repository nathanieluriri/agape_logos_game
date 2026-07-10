import 'package:freezed_annotation/freezed_annotation.dart';

part 'match_event.freezed.dart';

/// Powerup/effect kinds (contract 8.5). `unknown` guards forward compatibility.
enum MatchEventKind { letterFreeze, fogBank, scramble, wordSteal, unknown }

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

  /// `letter_freeze` payload: which rack letter index is locked (contract 8.5).
  int? get letterIndex => (payload['letterIndex'] as num?)?.toInt();

  /// `word_steal` payload: the word taken and the points transferred.
  String? get stolenWord => payload['word'] as String?;
  int get stolenPoints => (payload['points'] as num?)?.toInt() ?? 0;

  bool activeAt(int nowMillis) => expiresAt > nowMillis;
}
