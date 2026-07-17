import 'package:flutter/services.dart';

import 'haptic_platform.dart';

/// Signatures for the low-level platform vibration primitives, so they can be
/// injected in tests (defaulting to the real `platform*` functions from the
/// conditional-export selector).
typedef HasVibratorProbe = Future<bool> Function();
typedef VibrateFn = Future<void> Function(int durationMs, {int amplitude});
typedef VibratePatternFn = Future<void> Function(
  List<int> pattern, {
  List<int> amplitudes,
});

/// Haptic feedback abstraction for consistent vibration across the app.
///
/// Layered so it works on every platform the game ships to (Android + Web) and
/// on cheap phones without a dedicated haptics engine:
///  - Any device with a vibrator gets a tuned timed pulse, with amplitude
///    control where the hardware supports it (handled inside the platform layer).
///  - Web goes through the same calls: the platform layer drives the browser
///    Vibration API (`navigator.vibrate`), so web is no longer silent.
///  - A device that reports no vibrator falls back to Flutter's
///    [HapticFeedback], a silent no-op on unsupported platforms rather than an
///    error.
abstract interface class HapticService {
  /// Probe device capabilities once (has-vibrator). Best-effort and safe to
  /// call at bootstrap; calls also self-probe lazily.
  Future<void> init();

  /// Light impact (e.g. selection, minor UI button).
  Future<void> lightImpact();

  /// Medium impact (e.g. standard button press, word submit).
  Future<void> mediumImpact();

  /// Heavy impact (e.g. level win, combo milestone, destructive confirm).
  Future<void> heavyImpact();

  /// Strongest single feedback, reserved for in-game action buttons (letter
  /// wheel, shuffle, hint). Deliberately punchier than [heavyImpact].
  Future<void> gameImpact();

  /// Celebratory rising double-pulse for a combo streak (combo >= 2).
  Future<void> streakImpact();

  /// Distinct error buzz for a broken streak / invalid word: two short sharp
  /// pulses so a mistake never feels like success.
  Future<void> mistakeImpact();

  /// Selection tick (e.g. dragging across letters on the wheel).
  Future<void> selectionClick();

  /// Celebratory success burst for a claim or a level win: a rising three-beat
  /// pattern, richer than [streakImpact], so a genuine reward feels rewarding.
  Future<void> successPattern();

  /// The lightest possible tick, for high-frequency per-element feedback such
  /// as each tile filling in a staggered word-reveal cascade. Softer than
  /// [selectionClick] so a burst reads as texture, not a rattle.
  Future<void> tickImpact();

  /// Mute or unmute all haptic feedback.
  void setMuted(bool muted);
}

class FlutterHapticService implements HapticService {
  /// The platform primitives default to the real `platform*` functions; tests
  /// inject recording fakes to assert behaviour with no plugin or device.
  FlutterHapticService({
    HasVibratorProbe? hasVibrator,
    VibrateFn? vibrate,
    VibratePatternFn? vibratePattern,
  })  : _hasVibratorProbe = hasVibrator ?? platformHasVibrator,
        _vibrate = vibrate ?? platformVibrate,
        _vibratePattern = vibratePattern ?? platformVibratePattern;

  final HasVibratorProbe _hasVibratorProbe;
  final VibrateFn _vibrate;
  final VibratePatternFn _vibratePattern;

  bool _muted = false;
  bool _probed = false;
  bool _hasVibrator = false;

  @override
  Future<void> init() => _ensureProbed();

  Future<void> _ensureProbed() async {
    if (_probed) return;
    try {
      _hasVibrator = await _hasVibratorProbe();
    } catch (_) {
      // Never crash a button tap over capability probing.
      _hasVibrator = false;
    }
    _probed = true;
  }

  /// Central driver: a real vibrator gets a [durationMs] pulse (with [amplitude]
  /// where supported, applied inside the platform layer); everything else uses
  /// the Flutter [fallback]. [amplitude] is 1..255.
  Future<void> _play(
    int durationMs,
    int amplitude,
    Future<void> Function() fallback,
  ) async {
    if (_muted) return;
    await _ensureProbed();
    if (_hasVibrator) {
      await _vibrate(durationMs, amplitude: amplitude);
    } else {
      await fallback();
    }
  }

  /// Multi-pulse driver for expressive feedback (streak, mistake, success).
  /// [pattern] is the plugin's `[wait, buzz, wait, buzz, ...]` millisecond list;
  /// [amplitudes] aligns with it (0 for the waits) and is applied only where the
  /// hardware supports amplitude control. Devices without a vibrator replay
  /// [fallback] once per buzz so the feedback still reads as multiple beats.
  Future<void> _playPattern(
    List<int> pattern,
    List<int> amplitudes,
    Future<void> Function() fallback,
    int fallbackBeats,
  ) async {
    if (_muted) return;
    await _ensureProbed();
    if (_hasVibrator) {
      await _vibratePattern(pattern, amplitudes: amplitudes);
    } else {
      for (var i = 0; i < fallbackBeats; i++) {
        await fallback();
        await Future<void>.delayed(const Duration(milliseconds: 70));
      }
    }
  }

  // Durations/amplitudes are tuned punchier than a stock impact: on cheap phones
  // the buzz has to be long and strong enough to actually be felt.
  @override
  Future<void> tickImpact() => _play(10, 60, HapticFeedback.selectionClick);

  @override
  Future<void> selectionClick() =>
      _play(18, 90, HapticFeedback.selectionClick);

  @override
  Future<void> lightImpact() => _play(25, 120, HapticFeedback.lightImpact);

  @override
  Future<void> mediumImpact() => _play(40, 180, HapticFeedback.mediumImpact);

  @override
  Future<void> heavyImpact() => _play(70, 235, HapticFeedback.heavyImpact);

  @override
  Future<void> gameImpact() => _play(95, 255, HapticFeedback.heavyImpact);

  @override
  Future<void> streakImpact() => _playPattern(
        // Rising: short beat, gap, longer stronger beat.
        const [0, 35, 60, 90],
        const [0, 170, 0, 255],
        HapticFeedback.heavyImpact,
        2,
      );

  @override
  Future<void> mistakeImpact() => _playPattern(
        // Two equal sharp buzzes: unmistakably "wrong".
        const [0, 45, 70, 45],
        const [0, 230, 0, 230],
        HapticFeedback.heavyImpact,
        2,
      );

  @override
  Future<void> successPattern() => _playPattern(
        // Rising three-beat celebration: short, medium, long-and-strong.
        const [0, 40, 60, 55, 60, 90],
        const [0, 160, 0, 210, 0, 255],
        HapticFeedback.heavyImpact,
        3,
      );

  @override
  void setMuted(bool muted) => _muted = muted;
}
