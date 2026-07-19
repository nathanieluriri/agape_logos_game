import '../../puzzles/domain/puzzle.dart';
import '../domain/match.dart';
import '../domain/match_event.dart';
import '../domain/match_player.dart';
import '../domain/match_rack.dart';
import '../domain/match_settings.dart';

/// Firestore numbers arrive as int/double; coerce defensively.
int _asInt(Object? v) => (v as num?)?.toInt() ?? 0;

MatchPlayer matchPlayerFromWire(Map<String, dynamic> m) => MatchPlayer(
  uid: (m['uid'] as String?) ?? '',
  displayName: (m['displayName'] as String?) ?? 'Player',
  avatarId: (m['avatarId'] as String?) ?? 'avatar_01',
  isGuest: (m['isGuest'] as bool?) ?? false,
  ready: (m['ready'] as bool?) ?? false,
  connected: (m['connected'] as bool?) ?? false,
  score: _asInt(m['score']),
  wordsFound: _asInt(m['wordsFound']),
  endsAtBonusMs: _asInt(m['endsAtBonusMs']),
  lastWordAt: _asInt(m['lastWordAt']),
  finishedAt: _asInt(m['finishedAt']),
  lastSeen: _asInt(m['lastSeen']),
);

MatchActiveEffect matchActiveEffectFromWire(Map<String, dynamic> m) =>
    MatchActiveEffect(
      kind: matchEffectKindFromWire(m['kind'] as String?),
      byUid: (m['byUid'] as String?) ?? '',
      startedAt: _asInt(m['startedAt']),
      expiresAt: _asInt(m['expiresAt']),
      payload: (m['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
    );

MatchSettings matchSettingsFromWire(Map<String, dynamic> m) => MatchSettings(
  difficulty: matchDifficultyFromWire(m['difficulty'] as String?),
  durationSec: _asInt(m['durationSec']),
  rackSize: (m['rackSize'] as num?)?.toInt() ?? 7,
  theme: m['theme'] as String?,
  mode: m['mode'] == 'async' ? MatchMode.async : MatchMode.live,
);

Match matchFromSnapshot(String id, Map<String, dynamic> m) {
  final playersRaw =
      (m['players'] as Map?)?.cast<String, dynamic>() ??
      const <String, dynamic>{};
  final players = <String, MatchPlayer>{};
  playersRaw.forEach((uid, v) {
    players[uid] = matchPlayerFromWire((v as Map).cast<String, dynamic>());
  });
  final effectsRaw =
      (m['activeEffects'] as Map?)?.cast<String, dynamic>() ??
      const <String, dynamic>{};
  final activeEffects = <String, List<MatchActiveEffect>>{};
  effectsRaw.forEach((uid, v) {
    activeEffects[uid] = ((v as List?) ?? const [])
        .map((e) => matchActiveEffectFromWire((e as Map).cast<String, dynamic>()))
        .toList();
  });
  return Match(
    matchId: (m['matchId'] as String?) ?? id,
    code: (m['code'] as String?) ?? '',
    status: matchStatusFromWire(m['status'] as String?),
    participants: ((m['participants'] as List?) ?? const []).cast<String>(),
    playerOrder: ((m['playerOrder'] as List?) ?? const []).cast<String>(),
    createdBy: (m['createdBy'] as String?) ?? '',
    createdAt: _asInt(m['createdAt']),
    startedAt: _asInt(m['startedAt']),
    endsAt: _asInt(m['endsAt']),
    settings: matchSettingsFromWire(
      (m['settings'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    players: players,
    winner: m['winner'] as String?,
    puzzleId: m['puzzleId'] as String?,
    activeEffects: activeEffects,
  );
}

/// Answers arrive as `{length, enc}`; the ciphertext token is parked in
/// `PuzzleAnswer.word` until decrypted (mirrors `wirePuzzleToEncrypted`).
MatchRack matchRackFromSnapshot(String id, Map<String, dynamic> m) {
  final answers = (((m['answers'] as List?) ?? const [])).map((a) {
    final am = (a as Map).cast<String, dynamic>();
    return PuzzleAnswer(
      word: (am['enc'] as String?) ?? '',
      length: _asInt(am['length']),
      definition: null,
    );
  }).toList();
  return MatchRack(
    uid: (m['uid'] as String?) ?? id,
    letters: ((m['letters'] as List?) ?? const []).cast<String>(),
    letterKey: (m['letterKey'] as String?) ?? '',
    rackSize: (m['rackSize'] as num?)?.toInt() ?? answers.length,
    answers: answers,
    answerCount: (m['answerCount'] as num?)?.toInt() ?? answers.length,
    foundWords: ((m['foundWords'] as List?) ?? const []).cast<String>(),
  );
}

MatchEvent matchEventFromSnapshot(String id, Map<String, dynamic> m) =>
    MatchEvent(
      id: (m['id'] as String?) ?? id,
      at: _asInt(m['at']),
      byUid: (m['byUid'] as String?) ?? '',
      targetUid: (m['targetUid'] as String?) ?? '',
      kind: matchEventKindFromWire((m['kind'] as String?) ?? ''),
      payload: (m['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
      expiresAt: _asInt(m['expiresAt']),
    );
