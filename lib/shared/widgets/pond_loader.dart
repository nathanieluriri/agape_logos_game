// lib/shared/widgets/pond_loader.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design/motion/curves.dart';
import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/durations.dart';
import '../../core/design/tokens/sizing.dart';
import '../../core/design/tokens/spacing.dart';
import 'lotus_bloom.dart';
import 'petal_icon.dart';
import 'pond_progress_track.dart';

/// The app's premium pond loader: a lime-gold water track whose fill visibly
/// pushes a currency petal along its leading edge, with a soft wake, a shimmer
/// sheen, and a blooming-lotus pop when a real load completes. A label sits
/// beneath (also the accessibility label).
///
/// Two modes:
///  - INDETERMINATE ([progress] null, the default): the fill trickles forward,
///    decelerating toward a ceiling it never claims, and only completes when
///    a real load does. Used for every first-load wait (puzzle, store,
///    settings, account).
///  - DETERMINATE ([progress] 0..1): the fill tracks a real value and blooms at
///    1.0.
///
/// Reduced motion parks the fill at a calm partial (or the given [progress]),
/// stills the petal, and drops the sheen and bloom.
class PondLoader extends StatefulWidget {
  const PondLoader({super.key, this.label = 'Loading', this.progress});

  /// Text shown beneath the track (also the accessibility label).
  final String label;

  /// Real load progress in 0..1. Null selects the indeterminate breathing loop.
  final double? progress;

  @override
  State<PondLoader> createState() => _PondLoaderState();
}

class _PondLoaderState extends State<PondLoader> with TickerProviderStateMixin {
  /// Where the indeterminate fill rests when reduced motion is requested.
  static const double _reducedRamp = 0.33;

  /// Indeterminate ceiling: the trickle approaches but never claims full;
  /// only a real completion (determinate progress reaching 1.0) fills the bar.
  static const double _ceil = 0.9;

  late final AnimationController _trickle =
      AnimationController(vsync: this, duration: AppDurations.loaderTrickleSpan);
  late final AnimationController _bob =
      AnimationController(vsync: this, duration: AppDurations.petalBob);

  /// One-shot ease from the latched fill to 1.0 when the load completes.
  late final AnimationController _finish =
      AnimationController(vsync: this, duration: AppDurations.fast);

  bool _reduceMotion = false;
  bool _bloomed = false;

  /// Monotonic latch: the highest fill ever shown. Applied every frame, so
  /// the bar can never move backward, including across the indeterminate to
  /// determinate handoff and jittery caller progress.
  double _shown = 0;

  /// The latched fill at the moment the completion ease began.
  double _finishFrom = 0;

  bool get _determinate => widget.progress != null;
  bool get _finished => _determinate && widget.progress! >= 1.0;

  /// Nothing should keep ticking once the loader is finished (the completion
  /// ease has run) or when motion is disabled. The completion bloom is a
  /// one-shot and ends on its own, so a finished loader settles.
  bool get _atRest =>
      _reduceMotion || (_finished && _finish.isCompleted);

  @override
  void initState() {
    super.initState();
    // When the completion ease lands, nothing else re-evaluates the tickers
    // (no widget update happens), so re-sync here or the petal bob would spin
    // forever and pumpAndSettle-style waits would never settle.
    _finish.addStatusListener((status) {
      if (status == AnimationStatus.completed) _syncTickers();
    });
  }

  /// Single place that decides which tickers run, so entering/leaving
  /// determinate mode, completion, and reduced motion cannot disagree.
  void _syncTickers() {
    if (_finished &&
        !_reduceMotion &&
        _finish.status == AnimationStatus.dismissed) {
      _finishFrom = _shown;
      _finish.forward();
    }
    if (_atRest) {
      _trickle.stop();
      _bob.stop();
      return;
    }
    if (!_bob.isAnimating) _bob.repeat(reverse: true);
    if (_determinate) {
      if (_trickle.isAnimating) _trickle.stop();
    } else if (!_trickle.isAnimating && !_trickle.isCompleted) {
      // Forward only, never repeated: if the full span elapses the fill just
      // holds near the ceiling (the latch keeps the value).
      _trickle.forward();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _syncTickers();
  }

  @override
  void didUpdateWidget(PondLoader old) {
    super.didUpdateWidget(old);
    // Re-arms on any change to determinate mode or to the progress value
    // (notably crossing into 100%, which runs the completion ease).
    _syncTickers();
  }

  @override
  void dispose() {
    _trickle.dispose();
    _bob.dispose();
    _finish.dispose();
    super.dispose();
  }

  /// The fill fraction driving both the track and the petal position.
  /// Strictly non-decreasing for the lifetime of the State (see [_shown]).
  double _fraction() {
    if (_reduceMotion) {
      return _determinate ? widget.progress!.clamp(0.0, 1.0) : _reducedRamp;
    }
    final double raw;
    if (_finished) {
      final eased = AppCurves.enter.transform(_finish.value);
      raw = _finishFrom + (1 - _finishFrom) * eased;
    } else if (_determinate) {
      raw = widget.progress!.clamp(0.0, 1.0);
    } else {
      // Asymptotic trickle: fast start, visible slowdown, never reaches the
      // ceiling on its own. value = ceil * (1 - e^(-elapsed / tau)).
      final elapsed = _trickle.value *
          AppDurations.loaderTrickleSpan.inMilliseconds /
          1000.0;
      final tau = AppDurations.loaderTrickleTau.inMilliseconds / 1000.0;
      raw = _ceil * (1 - math.exp(-elapsed / tau));
    }
    _shown = math.max(_shown, raw);
    return _shown;
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.labelLarge;
    final showBloom =
        _determinate && !_reduceMotion && _finished && !_bloomed;
    return Semantics(
      label: widget.label,
      liveRegion: false,
      child: RepaintBoundary(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              // Rebuild on any controller; the petal is built once.
              animation: Listenable.merge([_trickle, _bob, _finish]),
              child: const PetalIcon(size: _PetalRider.petalSize),
              builder: (context, child) => _PetalRider(
                fraction: _fraction(),
                bob: _reduceMotion ? 0.5 : _bob.value,
                width: AppSizing.loaderTrackWidth,
                // A finished loader stops sweeping: no perpetual sheen at rest.
                shimmer: !_atRest,
                bloom: showBloom ? LotusBloom(onEnd: _onBloomEnd) : null,
                petal: child!,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ExcludeSemantics(
              child: Text(
                widget.label,
                style: base?.copyWith(color: AppColors.padLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onBloomEnd() {
    if (mounted) setState(() => _bloomed = true);
  }
}

/// The shared progress track with a currency petal riding the leading edge of
/// the fill. The petal straddles the fill front (centred on it) and rides up and
/// down with [bob], tilting a few degrees, with a soft wake beneath it. An
/// optional [bloom] overlay pops at the fill front on completion.
class _PetalRider extends StatelessWidget {
  const _PetalRider({
    required this.fraction,
    required this.bob,
    required this.width,
    required this.shimmer,
    required this.petal,
    this.bloom,
  });

  final double fraction;
  final double bob; // 0..1 bob phase.
  final double width;
  final bool shimmer;
  final Widget petal;
  final Widget? bloom;

  /// On-screen size of the riding petal.
  static const double petalSize = 30;

  /// Headroom above the track so the petal lifts off the bar instead of being
  /// clipped by it.
  static const double _lift = 16;

  /// Peak vertical bob travel (logical px) and peak tilt (radians).
  // PLAN: _bobTravel, _tilt, the wake radius, and the breathing bounds
  // (_floor/_ceil above) are first-pass. On-device, confirm the petal reads as
  // being PUSHED by the water, the bob is gentle, and the indeterminate loop
  // has no visible snap.
  static const double _bobTravel = 4;
  static const double _tilt = 0.12;

  @override
  Widget build(BuildContext context) {
    final value = fraction.clamp(0.0, 1.0);
    // Centre the petal ON the fill front (the leading edge pushes it).
    final frontX = value * width;
    final left = (frontX - petalSize / 2).clamp(0.0, width - petalSize);
    // bob 0..1 -> a smooth -1..1 offset via a sine-like triangle.
    final phase = (bob * 2 - 1);
    final dy = -_bobTravel * (1 - phase * phase); // lifts near mid-phase.
    final angle = _tilt * phase;
    return SizedBox(
      width: width,
      height: AppSizing.progressTrackHeight + _lift,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: PondProgressTrack(
              fraction: value,
              width: width,
              shimmer: shimmer,
            ),
          ),
          // Soft wake beneath the petal, at the fill front.
          Positioned(
            left: left,
            bottom: 0,
            child: IgnorePointer(
              child: CustomPaint(
                size: const Size(petalSize, petalSize),
                painter: _WakePainter(intensity: 1 - phase * phase),
              ),
            ),
          ),
          if (bloom != null)
            Positioned(
              left: (frontX - AppSizing.loaderBloom / 2)
                  .clamp(-petalSize, width),
              top: -_lift,
              child: bloom!,
            ),
          // The petal, straddling the fill front, bobbing and tilting.
          Positioned(
            left: left,
            top: 0,
            child: IgnorePointer(
              child: Transform.translate(
                offset: Offset(0, dy),
                child: Transform.rotate(angle: angle, child: petal),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A soft, low expanding ripple under the petal. Alpha is baked into the paint
/// (no `Opacity` widget) to stay off the hot-path cost list.
class _WakePainter extends CustomPainter {
  const _WakePainter({required this.intensity});

  final double intensity; // 0..1

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0) return;
    final center = Offset(size.width / 2, size.height * 0.9);
    final radius = size.width * (0.3 + 0.25 * intensity);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.petalWake
            .withValues(alpha: AppColors.petalWake.a * intensity),
    );
  }

  @override
  bool shouldRepaint(_WakePainter old) => old.intensity != intensity;
}
