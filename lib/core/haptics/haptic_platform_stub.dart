/// Fallback vibration primitives for a target that is neither Android (io) nor
/// web (js_interop). This app only ships to those two, so the stub is
/// effectively unreachable at runtime; it exists to satisfy the conditional
/// export's default branch.
///
/// Unlike `sync_scheduler_stub.dart` (which throws `UnsupportedError`), the
/// haptic stub returns safe no-ops. A haptic call must NEVER crash a button
/// tap: reporting "no vibrator" makes the service take its silent
/// `HapticFeedback` fallback instead of surfacing an error over a cosmetic buzz.
Future<bool> platformHasVibrator() async => false;

Future<void> platformVibrate(int durationMs, {int amplitude = -1}) async {}

Future<void> platformVibratePattern(
  List<int> pattern, {
  List<int> amplitudes = const <int>[],
}) async {}
