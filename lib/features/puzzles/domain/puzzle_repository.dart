import 'puzzle.dart';

abstract class PuzzleRepository {
  /// Cold-start recover->draw, then low-watermark refill. Network failures are
  /// swallowed; the local cache is the offline-playable source of truth.
  Future<void> ensureCacheReady();

  /// Recovery path for a stranded first login: force-refresh the answer key,
  /// then run [ensureCacheReady] (which seeds the bundled starter pack as a last
  /// resort). After this returns there is a playable puzzle to show.
  Future<void> recover();

  /// The next puzzle to play (lowest tier, then insert order), or null if none.
  Stream<Puzzle?> watchCurrentPuzzle();

  /// Optimistic write: mark the puzzle completed locally and enqueue the result.
  /// [level] is the progression level this result completed; when provided it is
  /// sent to the backend so `highestLevel` advances.
  Future<void> recordPuzzleResult(
    String puzzleId,
    int score,
    int completedAt, {
    int? level,
  });
}
