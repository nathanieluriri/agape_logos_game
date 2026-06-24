import 'package:drift/drift.dart';

import 'connection/connection.dart';
import 'daos/cached_puzzles_dao.dart';
import 'daos/level_results_dao.dart';
import 'daos/pending_mutations_dao.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [PendingMutations, LevelResults, CachedPuzzles],
  daos: [PendingMutationsDao, LevelResultsDao, CachedPuzzlesDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  /// Used by tests with an in-memory executor.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(cachedPuzzles);
          }
        },
      );
}
