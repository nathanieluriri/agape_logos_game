import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/durations.dart';
import 'fog_shader.dart';

/// Full-screen premium fog for the match screen. Mounted at the page root so it
/// covers the board AND the wheel. It is a purely visual disruptor: wrapped in
/// [IgnorePointer], so every touch falls straight through to the wheel beneath
/// and the player can still blind-play through the fog.
///
/// Self-ticking: while [fogUntil] is in the future and the platform allows
/// animation, it runs a [Ticker], animating the shader's time and a fade
/// in/out intensity, then stops and renders nothing. Under reduced motion
/// (`MediaQuery.disableAnimations`) or a shader that failed to compile, it
/// falls back to the flat [AppColors.fogTint] scrim instead: same "you cannot
/// read the board" outcome, but under reduced motion there is no per-frame
/// cost at all, just a single one-shot [Timer] that fires when [fogUntil] is
/// reached to drop the scrim.
class FogShaderOverlay extends StatefulWidget {
  const FogShaderOverlay({
    super.key,
    required this.fogUntil,
    required this.now,
  });

  /// Server-clock instant the fog lifts. Null means no fog.
  final DateTime? fogUntil;

  /// Server-adjusted clock reader, so a skewed device clock still lifts the fog
  /// on time.
  final DateTime Function() now;

  /// Fade the fog in over this window at the start, and out over it at the end.
  static const Duration _fade = AppDurations.normal;

  @override
  State<FogShaderOverlay> createState() => _FogShaderOverlayState();
}

class _FogShaderOverlayState extends State<FogShaderOverlay> {
  Ticker? _ticker;
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion != _reduceMotion) {
      _reduceMotion = reduceMotion;
      _sync();
    }
  }

  @override
  void didUpdateWidget(FogShaderOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  bool get _active {
    final until = widget.fogUntil;
    return until != null && widget.now().isBefore(until);
  }

  /// Chooses the ticking strategy for the current active/reduced-motion
  /// state: an animated per-frame [Ticker], a single one-shot [Timer], or
  /// neither while inactive.
  void _sync() {
    if (!_active) {
      _stopTicker();
      _stopTimer();
    } else if (_reduceMotion) {
      _stopTicker();
      _scheduleTimer();
    } else {
      _stopTimer();
      _startTicker();
    }
  }

  void _startTicker() {
    _ticker ??= Ticker((elapsed) {
      if (!mounted) return;
      if (!_active) {
        setState(() {});
        _stopTicker();
        return;
      }
      setState(() => _elapsed = elapsed);
    })
      ..start();
  }

  void _stopTicker() {
    _ticker?.dispose();
    _ticker = null;
  }

  /// Schedules a single `setState` at the moment [fogUntil] is reached, so
  /// the flat reduced-motion scrim drops on time without any per-frame work.
  void _scheduleTimer() {
    _stopTimer();
    final until = widget.fogUntil;
    if (until == null) return;
    final delay = until.difference(widget.now());
    _timer = Timer(delay.isNegative ? Duration.zero : delay, () {
      _timer = null;
      if (mounted) setState(() {});
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTicker();
    _stopTimer();
    super.dispose();
  }

  /// 0..1 fade: ramps up over the first [_fade], holds at 1, ramps down over
  /// the last [_fade] before [fogUntil].
  double _intensity() {
    final until = widget.fogUntil;
    if (until == null) return 0;
    final remainingMs = until.difference(widget.now()).inMilliseconds;
    if (remainingMs <= 0) return 0;
    final fadeMs = FogShaderOverlay._fade.inMilliseconds;
    final fadeOut = (remainingMs / fadeMs).clamp(0.0, 1.0);
    final fadeIn = (_elapsed.inMilliseconds / fadeMs).clamp(0.0, 1.0);
    return fadeIn < fadeOut ? fadeIn : fadeOut;
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (!_active) {
      child = const SizedBox.shrink();
    } else if (_reduceMotion) {
      // Flat scrim while active: no ticker running, no per-frame cost. A
      // single one-shot Timer (see _scheduleTimer) drops this at fogUntil.
      child = const ColoredBox(color: AppColors.fogTint);
    } else {
      final intensity = _intensity();
      if (intensity <= 0) {
        child = const SizedBox.shrink();
      } else if (fogProgram == null) {
        // Shader failed to compile: flat scrim, still ticker-driven fade
        // timing here since this branch only runs when motion is allowed.
        child = const ColoredBox(color: AppColors.fogTint);
      } else {
        child = RepaintBoundary(
          child: CustomPaint(
            painter: _FogPainter(
              program: fogProgram!,
              seconds: _elapsed.inMilliseconds / 1000.0,
              intensity: intensity,
            ),
            size: Size.infinite,
          ),
        );
      }
    }

    // IgnorePointer(ignoring: true): the fog never absorbs a touch, so the
    // wheel underneath stays fully playable through the fog.
    return IgnorePointer(child: child);
  }
}

class _FogPainter extends CustomPainter {
  _FogPainter({
    required this.program,
    required this.seconds,
    required this.intensity,
  });

  final ui.FragmentProgram program;
  final double seconds;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader()
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, seconds)
      ..setFloat(3, intensity);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_FogPainter old) =>
      old.seconds != seconds || old.intensity != intensity;
}
