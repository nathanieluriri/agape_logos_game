import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'game_settings_dao.g.dart';

/// Reads and writes the single-row [GameSettings]. Seeds defaults on demand so
/// the first read always returns a well-defined row.
@DriftAccessor(tables: [GameSettings])
class GameSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$GameSettingsDaoMixin {
  GameSettingsDao(super.db);

  /// Inserts the id = 0 row with defaults if it does not exist yet.
  Future<void> ensureDefault() => into(gameSettings).insert(
        const GameSettingsCompanion(id: Value(0)),
        mode: InsertMode.insertOrIgnore,
      );

  /// Watches the single settings row, seeding defaults first.
  Stream<GameSettingsRow> watch() async* {
    await ensureDefault();
    yield* (select(gameSettings)..where((t) => t.id.equals(0))).watchSingle();
  }

  Future<void> setSoundEffects(bool value) =>
      _set(GameSettingsCompanion(soundEffects: Value(value)));
  Future<void> setMusic(bool value) =>
      _set(GameSettingsCompanion(music: Value(value)));
  Future<void> setNotifications(bool value) =>
      _set(GameSettingsCompanion(notifications: Value(value)));
  Future<void> setHaptics(bool value) =>
      _set(GameSettingsCompanion(haptics: Value(value)));

  Future<void> _set(GameSettingsCompanion change) async {
    await ensureDefault();
    await (update(gameSettings)..where((t) => t.id.equals(0))).write(change);
  }
}
