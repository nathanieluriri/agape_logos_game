// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dictionary_entries_dao.dart';

// ignore_for_file: type=lint
mixin _$DictionaryEntriesDaoMixin on DatabaseAccessor<AppDatabase> {
  $DictionaryEntriesTable get dictionaryEntries =>
      attachedDatabase.dictionaryEntries;
  DictionaryEntriesDaoManager get managers => DictionaryEntriesDaoManager(this);
}

class DictionaryEntriesDaoManager {
  final _$DictionaryEntriesDaoMixin _db;
  DictionaryEntriesDaoManager(this._db);
  $$DictionaryEntriesTableTableManager get dictionaryEntries =>
      $$DictionaryEntriesTableTableManager(
        _db.attachedDatabase,
        _db.dictionaryEntries,
      );
}
