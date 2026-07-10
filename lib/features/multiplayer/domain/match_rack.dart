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
