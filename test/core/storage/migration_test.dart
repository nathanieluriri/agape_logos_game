import 'package:agape_logos_game/core/storage/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// The tables that existed at schema v1. Everything else is added by the
/// onUpgrade steps, so a v1 database is the oldest thing that can walk the whole
/// migration path.
const _v1Schema = <String>[
  '''
  CREATE TABLE pending_mutations (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    kind TEXT NOT NULL,
    payload TEXT NOT NULL,
    idempotency_key TEXT NOT NULL,
    status TEXT NOT NULL,
    attempts INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    next_attempt_at INTEGER NOT NULL DEFAULT 0,
    in_flight INTEGER NOT NULL DEFAULT 0
  )''',
  '''
  CREATE TABLE level_results (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    level INTEGER NOT NULL,
    score INTEGER NOT NULL,
    synced INTEGER NOT NULL DEFAULT 0,
    completed_at INTEGER NOT NULL
  )''',
];

/// cached_puzzles as it shipped at v2: no `encrypted` column (that arrived at
/// v6, via addColumn).
const _cachedPuzzlesV2 = '''
  CREATE TABLE cached_puzzles (
    puzzle_id TEXT NOT NULL PRIMARY KEY,
    tier TEXT NOT NULL,
    tier_rank INTEGER NOT NULL,
    rack_size INTEGER NOT NULL,
    letters_json TEXT NOT NULL,
    anchor TEXT NOT NULL,
    answers_json TEXT NOT NULL,
    answer_count INTEGER NOT NULL,
    order_index INTEGER NOT NULL,
    completed INTEGER NOT NULL DEFAULT 0,
    assigned_at INTEGER NOT NULL
  )''';

/// game_settings as it shipped at v3: no `tutorial_seen` column (v7).
const _gameSettingsV3 = '''
  CREATE TABLE game_settings (
    id INTEGER NOT NULL DEFAULT 0 PRIMARY KEY,
    sound_effects INTEGER NOT NULL DEFAULT 1,
    music INTEGER NOT NULL DEFAULT 1,
    notifications INTEGER NOT NULL DEFAULT 1,
    haptics INTEGER NOT NULL DEFAULT 1
  )''';

/// Opens an in-memory DB that looks the way a device on schema [version] really
/// looks on disk: the tables that existed then, with the columns they had then.
AppDatabase _dbAtVersion(int version) {
  final sqlite = sqlite3.openInMemory();
  for (final stmt in _v1Schema) {
    sqlite.execute(stmt);
  }
  if (version >= 2) sqlite.execute(_cachedPuzzlesV2);
  if (version >= 3) sqlite.execute(_gameSettingsV3);
  sqlite.execute('PRAGMA user_version = $version;');
  return AppDatabase.forTesting(NativeDatabase.opened(sqlite));
}

void main() {
  // Regression: onUpgrade created cachedProfile (from < 4) using the CURRENT
  // table definition, which already carries `coins`, and then ran addColumn
  // coins (from < 5) on top of it -> "duplicate column name: coins". The
  // migration threw on every open, so the schema version never advanced and the
  // app re-threw forever. Same shape for cachedPuzzles.encrypted and
  // gameSettings.tutorialSeen.
  // v1..v3: the versions where onUpgrade itself creates the table from the
  // current definition. A v4+ database already has cached_profile on disk
  // (without coins), so its addColumn step stays correct and is left alone.
  for (final from in <int>[1, 2, 3]) {
    test('migrates a v$from database up to the current schema', () async {
      final db = _dbAtVersion(from);
      addTearDown(db.close);

      // Forces the migration to run.
      await db.customSelect('SELECT 1').get();

      // Every column a later step adds must exist exactly once, whether the
      // table was created wholesale or upgraded in place.
      expect(await db.cachedProfileDao.read('nobody'), isNull);
      expect(await db.gameSettingsDao.watch().first, isNotNull);
      await db.customSelect('SELECT coins FROM cached_profile').get();
      await db.customSelect('SELECT encrypted FROM cached_puzzles').get();
      await db.customSelect('SELECT tutorial_seen FROM game_settings').get();
      await db
          .customSelect('SELECT powerup_tutorial_seen FROM game_settings')
          .get();

      final version = await db
          .customSelect('PRAGMA user_version;')
          .map((r) => r.read<int>('user_version'))
          .getSingle();
      expect(version, db.schemaVersion);
    });
  }
}
