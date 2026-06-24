import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Toggles the Flame ambient layer. Defaults on; widget tests override it off so
/// the game loop does not run. Also a natural seam for a future reduce-motion or
/// low-end-device setting.
final ambientEnabledProvider = Provider<bool>((ref) => true);

/// Whether the looping motion (Flame ambient + button controllers) is paused.
/// Set true while another route (the game) covers the home, so off-screen
/// animation does not burn CPU/battery.
class AmbientPaused extends Notifier<bool> {
  @override
  bool build() => false;

  void pause(bool value) => state = value;
}

final ambientPausedProvider =
    NotifierProvider<AmbientPaused, bool>(AmbientPaused.new);
