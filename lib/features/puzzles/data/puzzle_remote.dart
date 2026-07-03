import 'package:uuid/uuid.dart';

import '../../../core/network/api_client.dart';
import '../domain/puzzle.dart';

/// Thin transport for the puzzle serving endpoints (B). Returns parsed Puzzles
/// whose answers are still ENCRYPTED: each [PuzzleAnswer.word] holds the
/// backend ciphertext token (definition null, length in the clear). The
/// repository decrypts them at the read seam before the game sees them.
abstract class PuzzleRemote {
  Future<List<Puzzle>> draw(Map<String, int> composition);
  Future<List<Puzzle>> assignedIncomplete();
}

/// Builds a [Puzzle] from a wire puzzle whose answers are `{length, enc}`. The
/// ciphertext token is parked in [PuzzleAnswer.word] until it is decrypted.
Puzzle wirePuzzleToEncrypted(Map<String, dynamic> m) {
  final answers = (((m['answers'] as List?) ?? const [])).map((a) {
    final am = (a as Map).cast<String, dynamic>();
    return PuzzleAnswer(
      word: am['enc'] as String,
      length: (am['length'] as num).toInt(),
      definition: null,
    );
  }).toList();
  return Puzzle(
    tier: m['tier'] as String,
    rackSize: (m['rackSize'] as num).toInt(),
    letters: (m['letters'] as List).cast<String>(),
    letterKey: m['letterKey'] as String,
    anchor: m['anchor'] as String,
    answers: answers,
    answerCount: (m['answerCount'] as num).toInt(),
  );
}

class HttpPuzzleRemote implements PuzzleRemote {
  HttpPuzzleRemote(this._api, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final ApiClient _api;
  final Uuid _uuid;

  @override
  Future<List<Puzzle>> draw(Map<String, int> composition) async {
    final res = await _api.request<Map<String, dynamic>>(
      '/puzzles/draw',
      method: 'POST',
      data: composition,
      headers: {'idempotency-key': _uuid.v4()},
    );
    final byTier = (res.data?['byTier'] as Map?) ?? const {};
    final out = <Puzzle>[];
    for (final entry in byTier.values) {
      final puzzles = ((entry as Map)['puzzles'] as List?) ?? const [];
      for (final p in puzzles) {
        out.add(wirePuzzleToEncrypted((p as Map).cast<String, dynamic>()));
      }
    }
    return out;
  }

  @override
  Future<List<Puzzle>> assignedIncomplete() async {
    final res = await _api.request<Map<String, dynamic>>(
      '/puzzles/assigned?status=incomplete',
      method: 'GET',
    );
    final puzzles = (res.data?['puzzles'] as List?) ?? const [];
    return puzzles
        .map((p) => wirePuzzleToEncrypted((p as Map).cast<String, dynamic>()))
        .toList();
  }
}
