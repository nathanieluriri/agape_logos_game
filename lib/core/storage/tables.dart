import 'package:drift/drift.dart';

/// Durable, inspectable offline mutation queue. Optimistic writes enqueue rows
/// here; the sync engine drains them when the network is reachable.
class PendingMutations extends Table {
  TextColumn get id => text()();
  TextColumn get endpoint => text()();
  TextColumn get method => text()();
  TextColumn get payloadJson => text()();
  TextColumn get idempotencyKey => text()();
  TextColumn get kind => text()();
  IntColumn get createdAt => integer()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  IntColumn get nextAttemptAt => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Local cache of level results (UI source of truth for optimistic writes).
///
/// Row data class is named `LevelResultRow` to avoid colliding with the
/// `LevelResult` domain entity.
@DataClassName('LevelResultRow')
class LevelResults extends Table {
  TextColumn get id => text()();
  IntColumn get levelId => integer()();
  IntColumn get score => integer()();
  IntColumn get completedAt => integer()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Local cache of drawn puzzles (offline-playable source of truth for gameplay).
/// Rows are inserted by draw/recover and deleted after the result syncs.
@DataClassName('CachedPuzzleRow')
class CachedPuzzles extends Table {
  TextColumn get puzzleId => text()();
  TextColumn get tier => text()();
  IntColumn get tierRank => integer()(); // 0 easy, 1 medium, 2 hard, 3 expert
  IntColumn get rackSize => integer()();
  TextColumn get lettersJson => text()();
  TextColumn get anchor => text()();
  TextColumn get answersJson => text()();
  IntColumn get answerCount => integer()();
  IntColumn get orderIndex => integer()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  IntColumn get assignedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {puzzleId};
}

/// Single-row local game settings (the row id is always 0). Local-only,
/// never synced. Booleans default ON.
@DataClassName('GameSettingsRow')
class GameSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  BoolColumn get soundEffects => boolean().withDefault(const Constant(true))();
  BoolColumn get music => boolean().withDefault(const Constant(true))();
  BoolColumn get notifications => boolean().withDefault(const Constant(true))();
  BoolColumn get haptics => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
