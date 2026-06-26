// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_puzzles_dao.dart';

// ignore_for_file: type=lint
mixin _$CachedPuzzlesDaoMixin on DatabaseAccessor<AppDatabase> {
  $CachedPuzzlesTable get cachedPuzzles => attachedDatabase.cachedPuzzles;
  CachedPuzzlesDaoManager get managers => CachedPuzzlesDaoManager(this);
}

class CachedPuzzlesDaoManager {
  final _$CachedPuzzlesDaoMixin _db;
  CachedPuzzlesDaoManager(this._db);
  $$CachedPuzzlesTableTableManager get cachedPuzzles =>
      $$CachedPuzzlesTableTableManager(_db.attachedDatabase, _db.cachedPuzzles);
}
