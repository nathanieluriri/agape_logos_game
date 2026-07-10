import 'package:drift/drift.dart';

import '../../../core/storage/app_database.dart';
import '../domain/dictionary_entry.dart';

DictionaryEntry entryFromRow(DictionaryEntryRow row) => DictionaryEntry(
      word: row.word,
      definition: row.definition,
      tier: row.tier,
      level: row.level,
    );

/// Maps a domain entry to a cache row for [uid]. `word` is upper-cased so the
/// (uid, word) primary key de-duplicates case-insensitively, matching the
/// backend's dedupe.
DictionaryEntriesCompanion entryToCompanion(
  String uid,
  DictionaryEntry e,
  int foundAt,
) =>
    DictionaryEntriesCompanion.insert(
      uid: uid,
      word: e.word.toUpperCase(),
      definition: Value(e.definition),
      tier: e.tier,
      level: Value(e.level),
      foundAt: foundAt,
    );
