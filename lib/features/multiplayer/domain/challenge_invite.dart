/// An incoming friend challenge, mirroring the Firestore invite doc
/// `users/{uid}/challenges/{matchId}`. Plain value class: `mode` stays a String
/// (the server's wire vocabulary) and `at` is epoch millis (the doc stores a
/// Firestore Timestamp, converted by the read layer).
class ChallengeInvite {
  const ChallengeInvite({
    required this.matchId,
    required this.byUid,
    required this.handle,
    required this.displayName,
    required this.avatarId,
    required this.mode,
    required this.at,
  });

  final String matchId;
  final String byUid;
  final String handle;
  final String displayName;
  final String avatarId;
  final String mode; // 'live' | 'async'
  final int at;

  bool get isAsync => mode == 'async';
}
