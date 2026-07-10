import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'dictionary_entries_dao.g.dart';

/// Reads and writes the per-user [DictionaryEntries] cache. All reads are scoped
/// to a [uid] so a device that hosted multiple accounts never mixes their words.
@DriftAccessor(tables: [DictionaryEntries])
class DictionaryEntriesDao extends DatabaseAccessor<AppDatabase>
    with _$DictionaryEntriesDaoMixin {
  DictionaryEntriesDao(super.db);

  /// Streams [uid]'s cached words, alphabetically by word. The UI regroups by
  /// tier for display.
  Stream<List<DictionaryEntryRow>> watch(String uid) => (select(dictionaryEntries)
        ..where((t) => t.uid.equals(uid))
        ..orderBy([(t) => OrderingTerm.asc(t.word)]))
      .watch();

  /// One-shot read of [uid]'s cached words, alphabetically by word.
  Future<List<DictionaryEntryRow>> all(String uid) => (select(dictionaryEntries)
        ..where((t) => t.uid.equals(uid))
        ..orderBy([(t) => OrderingTerm.asc(t.word)]))
      .get();

  /// Write-through: replaces [uid]'s entire cached dictionary with [rows] in one
  /// transaction, so words no longer returned by the server (should never happen
  /// for solved history, but keeps the cache authoritative) do not linger. Other
  /// accounts' rows are untouched.
  Future<void> replaceAll(
    String uid,
    List<DictionaryEntriesCompanion> rows,
  ) =>
      transaction(() async {
        await (delete(dictionaryEntries)..where((t) => t.uid.equals(uid))).go();
        await batch((b) => b.insertAll(
              dictionaryEntries,
              rows,
              mode: InsertMode.insertOrReplace,
            ));
      });

  /// Drops every cached dictionary row (called on account deletion via
  /// [AppDatabase.clearLocalGameData]).
  Future<void> clear() => delete(dictionaryEntries).go();
}
