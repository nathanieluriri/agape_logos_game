import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/crypto/answer_cipher.dart';
import '../../../core/logging/app_logger.dart';
import '../../puzzles/domain/puzzle.dart';
import '../domain/match.dart';
import '../domain/match_event.dart';
import '../domain/match_rack.dart';
import 'match_mappers.dart';

/// The Firestore READ layer for multiplayer: the three participant-scoped
/// listeners from the contract (match doc, my private rack, events targeting
/// me). Writes never happen here (rules deny client writes); they go through
/// MatchRemote. Rack answers are decrypted in memory with the per-user key,
/// exactly like single-player puzzles (never at rest in plaintext).
class MatchFirestore {
  MatchFirestore(this._db, {required this._answerKey, AnswerCipher? cipher})
    : _cipher = cipher ?? AnswerCipher();

  final FirebaseFirestore _db;
  final Future<List<int>?> Function() _answerKey;
  final AnswerCipher _cipher;

  DocumentReference<Map<String, dynamic>> _matchDoc(String matchId) =>
      _db.collection('matches').doc(matchId);

  /// Live match doc (contract 8.1/8.2); emits null when the doc is absent.
  Stream<Match?> watchMatch(String matchId) =>
      _matchDoc(matchId).snapshots().map(
        (snap) => snap.exists ? matchFromSnapshot(snap.id, snap.data()!) : null,
      );

  /// My private rack (contract 8.3), answers decrypted in memory.
  Stream<MatchRack?> watchMyRack(String matchId, String uid) =>
      _matchDoc(matchId).collection('racks').doc(uid).snapshots().asyncMap((
        snap,
      ) async {
        if (!snap.exists) return null;
        return _decryptRack(matchRackFromSnapshot(snap.id, snap.data()!));
      });

  /// Events targeting [uid] (contract 8.4), oldest first so one-shot effects
  /// (scramble, word-steal) apply in order.
  Stream<List<MatchEvent>> watchEventsForMe(String matchId, String uid) =>
      _matchDoc(matchId)
          .collection('events')
          .where('targetUid', isEqualTo: uid)
          .orderBy('at')
          .snapshots()
          .map(
            (q) => q.docs
                .map((d) => matchEventFromSnapshot(d.id, d.data()))
                .toList(),
          );

  /// Decrypts the rack's answer tokens with the current user's key. On no key
  /// (a corner case in a live, online match) the rack is returned with the
  /// ciphertext still parked in `word`; `MatchRack.decrypted` is then false and
  /// the match page shows a brief "preparing your rack" state instead of leaking
  /// ciphertext. A per-token failure aborts to the same held state.
  Future<MatchRack> _decryptRack(MatchRack rack) async {
    if (rack.answers.isEmpty) return rack;
    final key = await _answerKey();
    if (key == null) {
      logger.info('match rack held: answer key not available yet');
      return rack;
    }
    try {
      final decrypted = <PuzzleAnswer>[];
      for (final a in rack.answers) {
        final r = await _cipher.decryptAnswer(key, a.word);
        decrypted.add(
          PuzzleAnswer(
            word: r.word,
            length: a.length,
            definition: r.definition,
          ),
        );
      }
      return rack.copyWith(answers: decrypted);
    } catch (e) {
      logger.warning('match rack decryption failed: $e');
      return rack;
    }
  }
}
