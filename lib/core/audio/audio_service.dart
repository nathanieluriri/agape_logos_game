import 'package:flame_audio/flame_audio.dart';

/// Game audio behind an interface so it can be muted/swapped/tested.
abstract interface class AudioService {
  /// Preload SFX (filenames under `assets/audio/`) to avoid first-play stalls.
  Future<void> preload(List<String> sfx);
  Future<void> playSfx(String name);
  void setMuted(bool muted);
}

class FlameAudioService implements AudioService {
  bool _muted = false;

  @override
  Future<void> preload(List<String> sfx) => FlameAudio.audioCache.loadAll(sfx);

  @override
  Future<void> playSfx(String name) async {
    if (_muted) return;
    await FlameAudio.play(name);
  }

  @override
  void setMuted(bool muted) => _muted = muted;
}
