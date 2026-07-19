import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/durations.dart';
import '../../../../core/design/tokens/sizing.dart';
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
    this.stacks = 1,
  });

  /// Server-clock instant the fog lifts. Null means no fog.
  final DateTime? fogUntil;

  /// Server-adjusted clock reader, so a skewed device clock still lifts the fog
  /// on time.
  final DateTime Function() now;

  /// Live fog-cast count (Task 2 stacks contract). A live effect implies a
  /// count of at least 1; `build` floors this at 1 (`math.max`) so a stray 0
  /// slipping through a fog=true/count-plumbing race never zeroes the alpha
  /// floor.
  final int stacks;

  /// Fade the fog in over this window at the start, and out over it at the end.
  static const Duration _fade = AppDurations.fogRoll;

  @override
  State<FogShaderOverlay> createState() => _FogShaderOverlayState();
}

class _FogShaderOverlayState extends State<FogShaderOverlay> {
  /// Fixed-sigma blur, built once for the whole app: the sigma never animates
  /// (animating it is the classic BackdropFilter jank), so the filter handle
  /// is shared across every fog frame instead of reallocated per build.
  static final ui.ImageFilter _blur = ui.ImageFilter.blur(
    sigmaX: AppSizing.fogBlurSigma,
    sigmaY: AppSizing.fogBlurSigma,
  );

  Ticker? _ticker;
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _reduceMotion = false;
  ui.FragmentShader? _shader;

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
    _shader?.dispose();
    super.dispose();
  }

  /// Lazily creates and caches the single reusable [ui.FragmentShader]
  /// instance for this overlay's lifetime, so `paint` never allocates a new
  /// shader handle per frame. Returns null while [fogProgram] hasn't
  /// compiled.
  ui.FragmentShader? _ensureShader() {
    _shader ??= fogProgram?.fragmentShader();
    return _shader;
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
      final shader = _ensureShader();
      if (intensity <= 0) {
        child = const SizedBox.shrink();
      } else if (shader == null) {
        // Shader failed to compile: flat scrim, still ticker-driven fade
        // timing here since this branch only runs when motion is allowed.
        child = const ColoredBox(color: AppColors.fogTint);
      } else {
        final coverFraction = (intensity * 1.6).clamp(0.0, 1.0);
        child = RepaintBoundary(
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRect(
                clipper: _FogBandClipper(fraction: coverFraction),
                child: BackdropFilter(
                  filter: _blur,
                  child: const SizedBox.expand(),
                ),
              ),
              CustomPaint(
                painter: _FogPainter(
                  shader: shader,
                  seconds: _elapsed.inMilliseconds / 1000.0,
                  intensity: intensity,
                  stacks: math.max(1, widget.stacks).toDouble(),
                ),
                size: Size.infinite,
              ),
            ],
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
    required this.shader,
    required this.seconds,
    required this.intensity,
    required this.stacks,
  });

  /// Single shader instance owned and disposed by
  /// [_FogShaderOverlayState], reused across every frame instead of being
  /// reallocated per paint.
  final ui.FragmentShader shader;
  final double seconds;
  final double intensity;
  final double stacks;

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, seconds)
      ..setFloat(3, intensity)
      ..setFloat(4, stacks);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_FogPainter old) =>
      old.seconds != seconds ||
      old.intensity != intensity ||
      old.stacks != stacks;
}

/// Clips the backdrop blur to the fogged band: from the top edge down to the
/// shader's front line (matching its 1.6 overshoot), so the blur rolls in and
/// lifts out with the mist instead of popping.
class _FogBandClipper extends CustomClipper<Rect> {
  const _FogBandClipper({required this.fraction});

  final double fraction;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width, size.height * fraction);

  @override
  bool shouldReclip(_FogBandClipper old) => old.fraction != fraction;
}
