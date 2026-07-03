import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_providers.dart';
import '../../../core/haptics/haptic_providers.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/storage/daos/game_settings_dao.dart';
import '../../../core/storage/storage_providers.dart';

final settingsDaoProvider = Provider<GameSettingsDao>(
  (ref) => ref.watch(appDatabaseProvider).gameSettingsDao,
);

/// Reactive settings the page watches.
final settingsProvider = StreamProvider<GameSettingsRow>(
  (ref) => ref.watch(settingsDaoProvider).watch(),
);

/// Writes settings. The sound setter also drives the real audio mute seam; the
/// other setters are persisted-only placeholders until their systems exist.
class SettingsController extends Notifier<void> {
  @override
  void build() {}

  GameSettingsDao get _dao => ref.read(settingsDaoProvider);

  Future<void> setSoundEffects(bool value) async {
    await _dao.setSoundEffects(value);
    ref.read(audioServiceProvider).setMuted(!value);
  }

  Future<void> setMusic(bool value) => _dao.setMusic(value);
  Future<void> setNotifications(bool value) => _dao.setNotifications(value);

  Future<void> setHaptics(bool value) async {
    await _dao.setHaptics(value);
    ref.read(hapticServiceProvider).setMuted(!value);
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, void>(SettingsController.new);
