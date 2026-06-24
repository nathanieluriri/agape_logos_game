import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'audio_service.dart';

/// The app's audio service. Overridden in `bootstrap()` with the instance whose
/// mute state is restored from settings; overridden with a fake in tests.
final audioServiceProvider =
    Provider<AudioService>((ref) => FlameAudioService());
