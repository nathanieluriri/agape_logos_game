import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'level_results_dao.g.dart';

@DriftAccessor(tables: [LevelResults])
class LevelResultsDao extends DatabaseAccessor<AppDatabase>
    with _$LevelResultsDaoMixin {
  LevelResultsDao(super.db);

  Future<void> upsert(LevelResultsCompanion row) =>
      into(levelResults).insertOnConflictUpdate(row);

  Stream<List<LevelResultRow>> watchAll() =>
      (select(levelResults)..orderBy([(t) => OrderingTerm.desc(t.completedAt)]))
          .watch();

  Future<void> markSynced(String id) =>
      (update(levelResults)..where((t) => t.id.equals(id)))
          .write(const LevelResultsCompanion(synced: Value(true)));
}
