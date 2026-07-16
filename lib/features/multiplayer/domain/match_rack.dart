import 'package:freezed_annotation/freezed_annotation.dart';

import '../../puzzles/domain/puzzle.dart';

part 'match_rack.freezed.dart';

/// The private per-player rack (contract 8.3), readable only by its owner. The
/// answers arrive encrypted (`word` holds the base64 token) and are decrypted in
/// memory by the rack listener using the per-user key. `foundWords` is
/// server-maintained as the owner submits.
@freezed
abstract class MatchRack with _$MatchRack {
  const factory MatchRack({
    required String uid,
    required List<String> letters,
    required String letterKey,
    required int rackSize,
    required List<PuzzleAnswer> answers,
    required int answerCount,
    required List<String> foundWords,
  }) = _MatchRack;

  const MatchRack._();

  /// Test-only convenience factory: builds an already-DECRYPTED rack (each
  /// answer's `word` equals its own plaintext, so `decrypted` is true) with no
  /// found words. Real racks arrive with encrypted answer tokens and go
  /// through the listener's decryption step; this skips that for unit tests
  /// that only need a playable rack shape.
  @visibleForTesting
  factory MatchRack.test({
    required List<String> letters,
    required List<String> answers,
  }) => MatchRack(
    uid: 'test-uid',
    letters: letters,
    letterKey: 'test-letter-key',
    rackSize: letters.length,
    answers: [
      for (final word in answers)
        PuzzleAnswer(word: word, length: word.length, definition: null),
    ],
    answerCount: answers.length,
    foundWords: const [],
  );

  /// True once every answer token has been decrypted to plaintext (each
  /// `word.length` then equals its declared `length`). While false the board
  /// must render nothing sensitive: the ciphertext is not a real word.
  bool get decrypted =>
      answers.isEmpty || answers.every((a) => a.word.length == a.length);

  /// Answers sorted shortest-first then alphabetically, for the word board.
  List<PuzzleAnswer> get targets {
    final list = [...answers];
    list.sort((a, b) {
      final byLen = a.length.compareTo(b.length);
      return byLen != 0 ? byLen : a.word.compareTo(b.word);
    });
    return list;
  }
}
