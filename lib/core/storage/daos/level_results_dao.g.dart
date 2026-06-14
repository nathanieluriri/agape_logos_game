// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'level_results_dao.dart';

// ignore_for_file: type=lint
mixin _$LevelResultsDaoMixin on DatabaseAccessor<AppDatabase> {
  $LevelResultsTable get levelResults => attachedDatabase.levelResults;
  LevelResultsDaoManager get managers => LevelResultsDaoManager(this);
}

class LevelResultsDaoManager {
  final _$LevelResultsDaoMixin _db;
  LevelResultsDaoManager(this._db);
  $$LevelResultsTableTableManager get levelResults =>
      $$LevelResultsTableTableManager(_db.attachedDatabase, _db.levelResults);
}
