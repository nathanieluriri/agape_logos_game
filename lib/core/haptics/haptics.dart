import 'haptic_service.dart';

/// Ambient access to the app's [HapticService] for provider-free widgets.
///
/// The shared pond buttons are deliberately Riverpod-free (so they also render
/// in the widget previewer, which must not touch providers/Drift/Flame). They
/// still need to buzz on tap, so they call [Haptics.instance] directly instead
/// of reading `hapticServiceProvider`.
///
/// `bootstrap()` assigns the SAME instance that backs `hapticServiceProvider`,
/// so the global mute state stays in one place. The default is a live service
/// so previews and tests never hit a null (the underlying plugin calls are safe
/// no-ops off-device).
class Haptics {
  Haptics._();

  static HapticService instance = FlutterHapticService();
}
