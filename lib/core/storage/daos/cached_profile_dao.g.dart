// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_profile_dao.dart';

// ignore_for_file: type=lint
mixin _$CachedProfileDaoMixin on DatabaseAccessor<AppDatabase> {
  $CachedProfileTable get cachedProfile => attachedDatabase.cachedProfile;
  CachedProfileDaoManager get managers => CachedProfileDaoManager(this);
}

class CachedProfileDaoManager {
  final _$CachedProfileDaoMixin _db;
  CachedProfileDaoManager(this._db);
  $$CachedProfileTableTableManager get cachedProfile =>
      $$CachedProfileTableTableManager(_db.attachedDatabase, _db.cachedProfile);
}
