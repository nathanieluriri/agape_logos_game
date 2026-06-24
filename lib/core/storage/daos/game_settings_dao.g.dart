// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_settings_dao.dart';

// ignore_for_file: type=lint
mixin _$GameSettingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $GameSettingsTable get gameSettings => attachedDatabase.gameSettings;
  GameSettingsDaoManager get managers => GameSettingsDaoManager(this);
}

class GameSettingsDaoManager {
  final _$GameSettingsDaoMixin _db;
  GameSettingsDaoManager(this._db);
  $$GameSettingsTableTableManager get gameSettings =>
      $$GameSettingsTableTableManager(_db.attachedDatabase, _db.gameSettings);
}
