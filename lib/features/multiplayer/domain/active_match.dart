/// A match currently in progress for the signed-in player, as served by
/// `GET /me/matches/active` (`ActiveMatchView`). Plain value class: `mode` and
/// `status` stay Strings (the server's wire vocabulary), and the two clock
/// fields are epoch millis. Used to render the "Your games" list on Resume.
class ActiveMatch {
  const ActiveMatch({
    required this.matchId,
    required this.mode,
    required this.status,
    required this.opponentUid,
    required this.opponentName,
    required this.myScore,
    required this.opponentScore,
    required this.startedAt,
    required this.endsAt,
  });

  final String matchId;
  final String mode; // 'live' | 'async'
  final String status; // 'lobby' | 'countdown' | 'active' | 'finished' | ...
  final String opponentUid;
  final String opponentName;
  final int myScore;
  final int opponentScore;
  final int startedAt;
  final int endsAt;

  bool get isAsync => mode == 'async';
  bool get isLobby => status == 'lobby';

  static int _asInt(Object? v) => (v as num?)?.toInt() ?? 0;

  factory ActiveMatch.fromJson(Map<String, dynamic> json) => ActiveMatch(
    matchId: (json['matchId'] as String?) ?? '',
    mode: (json['mode'] as String?) ?? 'live',
    status: (json['status'] as String?) ?? '',
    opponentUid: (json['opponentUid'] as String?) ?? '',
    opponentName: (json['opponentName'] as String?) ?? 'Opponent',
    myScore: _asInt(json['myScore']),
    opponentScore: _asInt(json['opponentScore']),
    startedAt: _asInt(json['startedAt']),
    endsAt: _asInt(json['endsAt']),
  );
}
