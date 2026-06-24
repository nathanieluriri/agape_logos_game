import 'package:uuid/uuid.dart';

import '../../../core/network/api_client.dart';
import '../domain/puzzle.dart';

/// Thin transport for the puzzle serving endpoints (B). Returns parsed Puzzles.
abstract class PuzzleRemote {
  Future<List<Puzzle>> draw(Map<String, int> composition);
  Future<List<Puzzle>> assignedIncomplete();
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
        out.add(Puzzle.fromJson((p as Map).cast<String, dynamic>()));
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
        .map((p) => Puzzle.fromJson((p as Map).cast<String, dynamic>()))
        .toList();
  }
}
