import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

/// Web vibration primitives, backed by the browser Vibration API
/// (`navigator.vibrate`). This is what makes web actually buzz: the pinned
/// `vibration` plugin has no web implementation, so before this file web was
/// completely silent.
///
/// Support notes (left deliberately defensive; a vibrate call must never throw):
///  - `navigator.vibrate` exists on Chromium and Android browsers. It is absent
///    on iOS Safari and some desktop browsers, where `platformHasVibrator`
///    returns false and the service falls back to a silent HapticFeedback.
///  - The API only takes durations, not amplitudes, so `amplitude` is ignored.
///  - The browser requires a prior user gesture (a tap) before it will vibrate;
///    every call site here already fires from a tap. A pre-gesture call is a
///    silent browser no-op, not an error.
// PLAN: compiled ONLY under dart.library.js_interop (web). Orchestrator
// verifies web actually vibrates in Chrome on Android (plan 08 Task 8). If
// navigator.vibrate's package:web parameter type rejects JSArray on the
// resolved version, wrap with .jsify().

bool _supported() {
  try {
    // Feature-detect without invoking: `has` comes from dart:js_interop_unsafe.
    return web.window.navigator.has('vibrate');
  } catch (_) {
    return false;
  }
}

Future<bool> platformHasVibrator() async => _supported();

Future<void> platformVibrate(int durationMs, {int amplitude = -1}) async {
  // Amplitude is not expressible in the browser API; the timed buzz is still felt.
  _vibrateMs(<int>[durationMs]);
}

Future<void> platformVibratePattern(
  List<int> pattern, {
  List<int> amplitudes = const <int>[],
}) async {
  // Format bridge: the `vibration` plugin's pattern is [wait, buzz, wait, buzz, ...]
  // (it starts with a leading wait), while the browser's pattern is
  // [buzz, pause, buzz, pause, ...] (it starts with a buzz). Every pattern this
  // app uses starts with a 0 wait, so dropping that leading 0 converts plugin
  // format to browser format cleanly (e.g. [0,35,60,90] -> buzz 35 / pause 60 /
  // buzz 90). Amplitudes are ignored (unsupported in the browser API).
  final browserPattern = pattern.isNotEmpty && pattern.first == 0
      ? pattern.sublist(1)
      : pattern;
  _vibrateMs(browserPattern);
}

/// Always calls `navigator.vibrate` with a JS array (a `[200]` single-element
/// array is equivalent to `vibrate(200)`), which keeps the interop robust across
/// `package:web` versions regardless of how the `VibratePattern` union is typed.
void _vibrateMs(List<int> pattern) {
  if (!_supported() || pattern.isEmpty) return;
  try {
    final jsPattern = <JSNumber>[for (final ms in pattern) ms.toJS].toJS;
    web.window.navigator.vibrate(jsPattern);
  } catch (_) {
    // Never let a cosmetic vibrate break a tap on an unsupported browser.
  }
}
