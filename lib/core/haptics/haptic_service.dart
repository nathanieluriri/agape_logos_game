import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Haptic feedback abstraction for consistent vibration across the app.
///
/// Layered so it works on every platform the game ships to (Android + Web) and
/// on cheap phones without a dedicated haptics engine:
///  - Any device with a vibrator (basic phones included) gets a tuned
///    [Vibration.vibrate] pulse, using amplitude control on Android 8+ where
///    it exists and a plain timed buzz everywhere else.
///  - Web goes through the same call: the plugin drives the browser Vibration
///    API (`navigator.vibrate`).
///  - A device that reports no vibrator falls back to Flutter's
///    [HapticFeedback], which is a silent no-op on unsupported platforms rather
///    than an error.
abstract interface class HapticService {
  /// Probe device capabilities once (has-vibrator, amplitude control).
  /// Best-effort and safe to call at bootstrap; calls also self-probe lazily.
  Future<void> init();

  /// Light impact (e.g. selection, minor UI button).
  Future<void> lightImpact();

  /// Medium impact (e.g. standard button press, word submit).
  Future<void> mediumImpact();

  /// Heavy impact (e.g. level win, combo milestone, destructive confirm).
  Future<void> heavyImpact();

  /// Strongest feedback, reserved for in-game action buttons (letter wheel,
  /// shuffle, hint). Deliberately punchier than [heavyImpact].
  Future<void> gameImpact();

  /// Selection tick (e.g. dragging across letters on the wheel).
  Future<void> selectionClick();

  /// Mute or unmute all haptic feedback.
  void setMuted(bool muted);
}

class FlutterHapticService implements HapticService {
  bool _muted = false;
  bool _probed = false;
  bool _hasVibrator = false;
  bool _hasAmplitude = false;

  @override
  Future<void> init() => _ensureProbed();

  Future<void> _ensureProbed() async {
    if (_probed) return;
    try {
      _hasVibrator = await Vibration.hasVibrator();
      _hasAmplitude = _hasVibrator && await Vibration.hasAmplitudeControl();
    } catch (_) {
      // Plugin missing / platform channel unavailable: fall back to
      // HapticFeedback and never crash a button tap over haptics.
      _hasVibrator = false;
      _hasAmplitude = false;
    }
    _probed = true;
  }

  /// Central driver: a real vibrator gets a [durationMs] pulse (with [amplitude]
  /// when the hardware supports it); everything else uses the Flutter
  /// [fallback]. [amplitude] is 1..255; ignored when amplitude control is
  /// absent (basic phones and web still feel the timed pulse).
  Future<void> _play(
    int durationMs,
    int amplitude,
    Future<void> Function() fallback,
  ) async {
    if (_muted) return;
    await _ensureProbed();
    if (_hasVibrator) {
      await Vibration.vibrate(
        duration: durationMs,
        amplitude: _hasAmplitude ? amplitude : -1,
      );
    } else {
      await fallback();
    }
  }

  @override
  Future<void> selectionClick() =>
      _play(10, 45, HapticFeedback.selectionClick);

  @override
  Future<void> lightImpact() => _play(15, 70, HapticFeedback.lightImpact);

  @override
  Future<void> mediumImpact() => _play(28, 140, HapticFeedback.mediumImpact);

  @override
  Future<void> heavyImpact() => _play(45, 210, HapticFeedback.heavyImpact);

  @override
  Future<void> gameImpact() => _play(60, 255, HapticFeedback.heavyImpact);

  @override
  void setMuted(bool muted) => _muted = muted;
}
