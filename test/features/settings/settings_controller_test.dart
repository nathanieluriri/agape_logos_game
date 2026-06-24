import 'package:agape_logos_game/core/audio/audio_providers.dart';
import 'package:agape_logos_game/core/audio/audio_service.dart';
import 'package:agape_logos_game/core/storage/app_database.dart';
import 'package:agape_logos_game/core/storage/storage_providers.dart';
import 'package:agape_logos_game/features/settings/application/settings_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAudio implements AudioService {
  bool? muted;
  @override
  Future<void> preload(List<String> sfx) async {}
  @override
  Future<void> playSfx(String name) async {}
  @override
  void setMuted(bool value) => muted = value;
}

void main() {
  late AppDatabase db;
  late _FakeAudio audio;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    audio = _FakeAudio();
    container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      audioServiceProvider.overrideWithValue(audio),
    ]);
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('setSoundEffects persists and mutes the audio service', () async {
    await container
        .read(settingsControllerProvider.notifier)
        .setSoundEffects(false);

    final row = await db.gameSettingsDao.watch().first;
    expect(row.soundEffects, isFalse);
    expect(audio.muted, isTrue); // muted == !soundEffects
  });

  test('setNotifications persists and does not touch audio', () async {
    await container
        .read(settingsControllerProvider.notifier)
        .setNotifications(false);

    final row = await db.gameSettingsDao.watch().first;
    expect(row.notifications, isFalse);
    expect(audio.muted, isNull);
  });
}
