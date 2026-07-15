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

  /// Watches the single settings row, seeding defaults on demand.
  ///
  /// The first emission is never gated on the seed write completing: we watch
  /// the row nullably and, whenever it is missing, seed and re-read. This keeps
  /// the stream from stalling in a loading state when it is driven through a
  /// Riverpod `StreamProvider` (a leading `await` before the first `yield`
  /// could otherwise leave the provider perpetually loading).
  Stream<GameSettingsRow> watch() {
    final selectRow = select(gameSettings)..where((t) => t.id.equals(0));
    return selectRow.watchSingleOrNull().asyncMap((row) async {
      if (row != null) return row;
      await ensureDefault();
      return (select(gameSettings)..where((t) => t.id.equals(0))).getSingle();
    });
  }

  Future<void> setSoundEffects(bool value) =>
      _set(GameSettingsCompanion(soundEffects: Value(value)));
  Future<void> setMusic(bool value) =>
      _set(GameSettingsCompanion(music: Value(value)));
  Future<void> setNotifications(bool value) =>
      _set(GameSettingsCompanion(notifications: Value(value)));
  Future<void> setHaptics(bool value) =>
      _set(GameSettingsCompanion(haptics: Value(value)));
  Future<void> setTutorialSeen(bool value) =>
      _set(GameSettingsCompanion(tutorialSeen: Value(value)));
  Future<void> setPowerupTutorialSeen(bool value) =>
      _set(GameSettingsCompanion(powerupTutorialSeen: Value(value)));

  Future<void> _set(GameSettingsCompanion change) async {
    await ensureDefault();
    await (update(gameSettings)..where((t) => t.id.equals(0))).write(change);
  }
}
