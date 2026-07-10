// lib/shared/widgets/pond_loader.dart
import 'package:flutter/material.dart';

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
///  - INDETERMINATE ([progress] null, the default): the water breathes forward
///    and back so the petal keeps gliding while a load is in flight. Used for
///    every first-load wait (puzzle, store, settings, account).
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

  /// Indeterminate breathing bounds: the water advances to [_ceil] then recedes
  /// to [_floor], pushing and drawing back the petal without a hard reset.
  static const double _floor = 0.08;
  static const double _ceil = 0.92;

  late final AnimationController _loop =
      AnimationController(vsync: this, duration: AppDurations.loaderLoop);
  late final AnimationController _bob =
      AnimationController(vsync: this, duration: AppDurations.petalBob);

  bool _reduceMotion = false;
  bool _bloomed = false;

  bool get _determinate => widget.progress != null;

  /// Nothing should keep ticking once the loader is finished (a determinate
  /// loader at 100%) or when motion is disabled. The completion bloom is a
  /// one-shot and ends on its own, so a finished loader settles.
  bool get _atRest => _reduceMotion || (_determinate && _fractionAtFull());

  /// Single place that decides which tickers run, so entering/leaving
  /// determinate mode, reaching 100%, and reduced motion cannot disagree.
  void _syncTickers() {
    if (_atRest) {
      _loop.stop();
      _bob.stop();
      return;
    }
    if (!_bob.isAnimating) _bob.repeat(reverse: true);
    if (_determinate) {
      if (_loop.isAnimating) _loop.stop();
    } else if (!_loop.isAnimating) {
      _loop.repeat();
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
    // (notably crossing into 100%, which parks the loader).
    _syncTickers();
  }

  @override
  void dispose() {
    _loop.dispose();
    _bob.dispose();
    super.dispose();
  }

  /// The fill fraction driving both the track and the petal position.
  double _fraction() {
    if (_determinate) return widget.progress!.clamp(0.0, 1.0);
    if (_reduceMotion) return _reducedRamp;
    // Triangle 0..1..0 over the loop, eased into a gentle breath.
    final t = _loop.value;
    final tri = t < 0.5 ? t * 2 : (1 - t) * 2;
    return _floor + (_ceil - _floor) * Curves.easeInOut.transform(tri);
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.labelLarge;
    final showBloom =
        _determinate && !_reduceMotion && _fractionAtFull() && !_bloomed;
    return Semantics(
      label: widget.label,
      liveRegion: false,
      child: RepaintBoundary(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              // Rebuild on either controller; the petal is built once.
              animation: Listenable.merge([_loop, _bob]),
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

  bool _fractionAtFull() => (widget.progress ?? 0) >= 1.0;

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
