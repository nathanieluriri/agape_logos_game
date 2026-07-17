import 'package:vibration/vibration.dart';

/// Android (and any dart:io target) vibration primitives, backed by the
/// `vibration` plugin. This is where all direct `package:vibration` use now
/// lives, so `FlutterHapticService` stays platform-agnostic.

/// Cached amplitude-control support. Queried at most once: it hits a platform
/// channel and never changes for the life of the process.
bool? _hasAmplitude;

// PLAN: Vibration.hasVibrator() returns Future<bool> in vibration 3.x (the
// current pin). If a version bump makes it Future<bool?>, add `?? false`.
Future<bool> platformHasVibrator() async {
  try {
    return await Vibration.hasVibrator();
  } catch (_) {
    // Plugin missing / channel unavailable (e.g. a unit test on the VM): report
    // no vibrator so the service takes its HapticFeedback fallback.
    return false;
  }
}

Future<bool> _amplitudeControl() async {
  final cached = _hasAmplitude;
  if (cached != null) return cached;
  try {
    return _hasAmplitude = await Vibration.hasAmplitudeControl();
  } catch (_) {
    return _hasAmplitude = false;
  }
}

Future<void> platformVibrate(int durationMs, {int amplitude = -1}) async {
  // Apply amplitude only when asked for (1..255) AND the hardware supports it;
  // otherwise pass -1 so basic phones still feel the plain timed pulse.
  final useAmplitude = amplitude > 0 && await _amplitudeControl();
  await Vibration.vibrate(
    duration: durationMs,
    amplitude: useAmplitude ? amplitude : -1,
  );
}

Future<void> platformVibratePattern(
  List<int> pattern, {
  List<int> amplitudes = const <int>[],
}) async {
  final useAmplitude = amplitudes.isNotEmpty && await _amplitudeControl();
  await Vibration.vibrate(
    pattern: pattern,
    intensities: useAmplitude ? amplitudes : const <int>[],
  );
}
