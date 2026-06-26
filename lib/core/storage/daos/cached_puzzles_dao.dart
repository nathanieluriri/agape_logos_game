import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'cached_puzzles_dao.g.dart';

@DriftAccessor(tables: [CachedPuzzles])
class CachedPuzzlesDao extends DatabaseAccessor<AppDatabase>
    with _$CachedPuzzlesDaoMixin {
  CachedPuzzlesDao(super.db);

  Future<void> insertAll(List<CachedPuzzlesCompanion> rows) async {
    await batch((b) =>
        b.insertAll(cachedPuzzles, rows, mode: InsertMode.insertOrIgnore));
  }

  Future<int> nextOrderIndex() async {
    final maxExpr = cachedPuzzles.orderIndex.max();
    final q = selectOnly(cachedPuzzles)..addColumns([maxExpr]);
    final current = (await q.getSingleOrNull())?.read(maxExpr);
    return (current ?? -1) + 1;
  }

  Future<int> unplayedCount() async {
    final count = cachedPuzzles.puzzleId.count();
    final q = selectOnly(cachedPuzzles)
      ..addColumns([count])
      ..where(cachedPuzzles.completed.equals(false));
    return (await q.getSingle()).read(count) ?? 0;
  }

  Future<Map<String, int>> remainingByTier() async {
    final count = cachedPuzzles.puzzleId.count();
    final q = selectOnly(cachedPuzzles)
      ..addColumns([cachedPuzzles.tier, count])
      ..where(cachedPuzzles.completed.equals(false))
      ..groupBy([cachedPuzzles.tier]);
    final rows = await q.get();
    return {
      for (final r in rows) r.read(cachedPuzzles.tier)!: r.read(count) ?? 0,
    };
  }

  Stream<CachedPuzzleRow?> watchCurrentPuzzle() => (select(cachedPuzzles)
        ..where((t) => t.completed.equals(false))
        ..orderBy([
          (t) => OrderingTerm.asc(t.tierRank),
          (t) => OrderingTerm.asc(t.orderIndex),
        ])
        ..limit(1))
      .watchSingleOrNull();

  Future<CachedPuzzleRow?> currentPuzzle() => (select(cachedPuzzles)
        ..where((t) => t.completed.equals(false))
        ..orderBy([
          (t) => OrderingTerm.asc(t.tierRank),
          (t) => OrderingTerm.asc(t.orderIndex),
        ])
        ..limit(1))
      .getSingleOrNull();

  Future<void> markCompleted(String puzzleId) =>
      (update(cachedPuzzles)..where((t) => t.puzzleId.equals(puzzleId)))
          .write(const CachedPuzzlesCompanion(completed: Value(true)));

  Future<void> deleteByPuzzleId(String puzzleId) =>
      (delete(cachedPuzzles)..where((t) => t.puzzleId.equals(puzzleId))).go();
}
