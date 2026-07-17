import 'package:drift/drift.dart';

import 'connection/connection.dart';
import 'daos/cached_profile_dao.dart';
import 'daos/cached_puzzles_dao.dart';
import 'daos/dictionary_entries_dao.dart';
import 'daos/game_settings_dao.dart';
import 'daos/level_results_dao.dart';
import 'daos/pending_mutations_dao.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    PendingMutations,
    LevelResults,
    CachedPuzzles,
    GameSettings,
    CachedProfile,
    DictionaryEntries,
  ],
  daos: [
    PendingMutationsDao,
    LevelResultsDao,
    CachedPuzzlesDao,
    GameSettingsDao,
    CachedProfileDao,
    DictionaryEntriesDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  /// Used by tests with an in-memory executor.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // createTable builds the table from its CURRENT definition, so a table
          // created here already has every column a later step would add. Each
          // addColumn therefore belongs to the `else` branch: it is only for a
          // database old enough to have the table but not the column. Running
          // both (as this used to) throws "duplicate column name", and because
          // the migration then never completes, the schema version never
          // advances and the app re-throws on every single open.
          if (from < 2) {
            await m.createTable(cachedPuzzles);
          } else if (from < 6) {
            await m.addColumn(cachedPuzzles, cachedPuzzles.encrypted);
          }
          if (from < 3) {
            await m.createTable(gameSettings);
          } else if (from < 7) {
            await m.addColumn(gameSettings, gameSettings.tutorialSeen);
            await m.addColumn(gameSettings, gameSettings.powerupTutorialSeen);
          } else if (from < 10) {
            await m.addColumn(gameSettings, gameSettings.powerupTutorialSeen);
          }
          if (from < 4) {
            await m.createTable(cachedProfile);
          } else if (from < 5) {
            await m.addColumn(cachedProfile, cachedProfile.coins);
          }
          if (from < 8) {
            // New puzzle generation (v3): drop puzzles cached by the old
            // algorithm so the device redraws from the regenerated pool.
            await delete(cachedPuzzles).go();
          }
          if (from < 9) {
            await m.createTable(dictionaryEntries);
          }
        },
      );

  /// Wipes local game progress (used when an account is deleted). Leaves the
  /// device-level [GameSettings] untouched. Drops the cached profile so a
  /// deleted account's data never lingers for the next user.
  Future<void> clearLocalGameData() => transaction(() async {
        await delete(levelResults).go();
        await delete(pendingMutations).go();
        await delete(cachedProfile).go();
        await delete(dictionaryEntries).go();
      });
}
