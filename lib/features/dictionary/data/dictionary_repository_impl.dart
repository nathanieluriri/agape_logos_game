import 'package:dio/dio.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/storage/app_database.dart';
import '../domain/dictionary_entry.dart';
import '../domain/dictionary_repository.dart';
import 'dictionary_mappers.dart';
import 'dictionary_remote.dart';

/// CachedRead implementation of [DictionaryRepository]: `GET /me/dictionary`
/// fetched online with write-through to the [DictionaryEntries] table, served
/// from cache when offline. Same shape as ProfileRepositoryImpl.fetch.
class DictionaryRepositoryImpl implements DictionaryRepository {
  DictionaryRepositoryImpl(this.db, this._remote);

  final AppDatabase db;
  final DictionaryRemote _remote;

  @override
  Future<List<DictionaryEntry>> fetch(String uid) async {
    try {
      final entries = await _remote.dictionary();
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.dictionaryEntriesDao.replaceAll(
        uid,
        [for (final e in entries) entryToCompanion(uid, e, now)],
      );
      return entries;
    } on DioException catch (e) {
      // Offline or transient: serve the cached dictionary for this account.
      logger.info('dictionary fetch offline, serving cache: ${e.message}');
      final rows = await db.dictionaryEntriesDao.all(uid);
      return rows.map(entryFromRow).toList();
    }
  }

  @override
  Stream<List<DictionaryEntry>> watch(String uid) => db.dictionaryEntriesDao
      .watch(uid)
      .map((rows) => rows.map(entryFromRow).toList());
}
