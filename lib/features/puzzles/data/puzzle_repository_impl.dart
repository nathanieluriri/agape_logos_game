import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/offline/mutation.dart';
import '../../../core/offline/offline_aware_repository.dart';
import '../../../core/storage/app_database.dart';
import '../puzzles_config.dart';
import '../domain/puzzle.dart';
import '../domain/puzzle_repository.dart';
import 'puzzle_mappers.dart';
import 'puzzle_remote.dart';

class PuzzleRepositoryImpl
    with OfflineAwareRepository
    implements PuzzleRepository {
  PuzzleRepositoryImpl(this.db, this._remote, {Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  @override
  final AppDatabase db;
  final PuzzleRemote _remote;
  final Uuid _uuid;

  @override
  Future<void> ensureCacheReady() async {
    try {
      if (await db.cachedPuzzlesDao.unplayedCount() == 0) {
        final recovered = await _remote.assignedIncomplete();
        if (recovered.isNotEmpty) await _insert(recovered);
      }
      if (await db.cachedPuzzlesDao.unplayedCount() < kRefillThreshold) {
        final drawn = await _remote.draw(kDrawComposition);
        if (drawn.isNotEmpty) await _insert(drawn);
      }
    } on DioException catch (e) {
      // Offline or transient: leave the cache as-is and play what we have.
      logger.info('puzzle cache refill skipped: ${e.message}');
    }
  }

  Future<void> _insert(List<Puzzle> puzzles) async {
    var idx = await db.cachedPuzzlesDao.nextOrderIndex();
    final now = DateTime.now().millisecondsSinceEpoch;
    final rows = [
      for (final p in puzzles)
        puzzleToCompanion(p, orderIndex: idx++, assignedAt: now),
    ];
    await db.cachedPuzzlesDao.insertAll(rows);
  }

  @override
  Stream<Puzzle?> watchCurrentPuzzle() => db.cachedPuzzlesDao
      .watchCurrentPuzzle()
      .map((row) => row == null ? null : puzzleFromRow(row));

  @override
  Future<Map<String, int>> remainingByTier() =>
      db.cachedPuzzlesDao.remainingByTier();

  @override
  Future<void> recordPuzzleResult(
    String puzzleId,
    int score,
    int completedAt,
  ) async {
    await db.cachedPuzzlesDao.markCompleted(puzzleId);
    await enqueueMutation(
      PendingMutationData(
        id: _uuid.v4(),
        endpoint: '/puzzles/$puzzleId/result',
        method: 'POST',
        payloadJson: jsonEncode({'score': score, 'completedAt': completedAt}),
        idempotencyKey: puzzleId,
        kind: kPuzzleResultKind,
        createdAt: completedAt,
      ),
    );
  }
}
