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
  // True when [answersJson] holds per-answer ciphertext tokens (backend
  // puzzles). The read seam decrypts these before handing the puzzle to the
  // game. False for the bundled plaintext starter pack.
  BoolColumn get encrypted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {puzzleId};
}

/// Local cache of the signed-in user's solved-word dictionary. Written through
/// from `GET /me/dictionary`, served offline. Keyed by (uid, word) so reads are
/// scoped to one account (a guest -> Google switch never surfaces the previous
/// account's words), matching the CachedProfile uid-guard. `word` is stored
/// UPPERCASE by the write-through mapper so the PK dedupe matches the backend.
@DataClassName('DictionaryEntryRow')
class DictionaryEntries extends Table {
  TextColumn get uid => text()();
  TextColumn get word => text()();
  TextColumn get definition => text().nullable()();
  TextColumn get tier => text()();
  // The progression level this word was first solved at, if the server sends it.
  // Nullable: the assignment ledger does not retain a per-puzzle level today, so
  // the endpoint omits it and the UI groups by tier. Kept for future use.
  IntColumn get level => integer().nullable()();
  // When this row was written through to the cache (epoch millis).
  IntColumn get foundAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {uid, word};
}

/// Single-row local game settings (the row id is always 0). Local-only,
/// never synced. Booleans default ON, except [tutorialSeen] which defaults
/// OFF (a fresh install has not seen the first-play tutorial yet).
@DataClassName('GameSettingsRow')
class GameSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  BoolColumn get soundEffects => boolean().withDefault(const Constant(true))();
  BoolColumn get music => boolean().withDefault(const Constant(true))();
  BoolColumn get notifications => boolean().withDefault(const Constant(true))();
  BoolColumn get haptics => boolean().withDefault(const Constant(true))();
  BoolColumn get tutorialSeen => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Single-row cache of the signed-in user's server profile (the row id is
/// always 0). Written through on a successful `GET /me`; served offline. The
/// stored [uid] guards reads so a previous user's profile is never surfaced
/// after a different account signs in on the same device.
@DataClassName('CachedProfileRow')
class CachedProfile extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  TextColumn get uid => text()();
  TextColumn get displayName => text()();
  TextColumn get avatarId => text()();
  TextColumn get locale => text()();
  BoolColumn get soundEnabled => boolean()();
  BoolColumn get musicEnabled => boolean()();
  IntColumn get highestLevel => integer()();
  IntColumn get totalScore => integer()();
  // Server-owned wallet balance. Defaulted so the v4 -> v5 migration can add the
  // column to existing rows without a value; a real balance arrives on the next
  // `GET /me` write-through.
  IntColumn get coins => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
