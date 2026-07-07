// lib/shared/widgets/pond_loader.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/design/motion/curves.dart';
import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/durations.dart';
import '../../core/design/tokens/sizing.dart';
import '../../core/design/tokens/spacing.dart';
import 'pond_progress_track.dart';

/// Minimal determinate pond loader: a lime-gold progress track with a currency
/// petal riding the leading edge of the fill, and a label beneath. The fill
/// eases toward (but never claims) full while a load is in flight, so the petal
/// keeps visibly gliding along the bar rather than the screen sitting blank.
/// Holds a steady partial fill (petal parked) when reduced motion is requested.
///
/// Used for every first-load wait: the puzzle words loading in, the store,
/// settings, the account. The [label] says which screen is coming.
class PondLoader extends StatefulWidget {
  const PondLoader({super.key, this.label = 'Loading'});

  /// Text shown beneath the track (also the accessibility label).
  final String label;

  @override
  State<PondLoader> createState() => _PondLoaderState();
}

class _PondLoaderState extends State<PondLoader>
    with SingleTickerProviderStateMixin {
  /// The bar eases toward this ceiling but never reaches 1.0, so the petal
  /// never parks at the end while a load is still in flight.
  static const double _fillCeiling = 0.99;

  /// Where the fill rests when reduced motion is requested (a calm partial).
  static const double _reducedRamp = 0.33;

  late final AnimationController _ramp =
      AnimationController(vsync: this, duration: AppDurations.loaderRamp);
  late final Animation<double> _fill =
      CurvedAnimation(parent: _ramp, curve: AppCurves.enter);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _ramp.stop();
      _ramp.value = _reducedRamp;
    } else if (!_ramp.isAnimating && _ramp.value == 0) {
      _ramp.forward();
    }
  }

  @override
  void dispose() {
    _ramp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.labelLarge;
    return Semantics(
      label: widget.label,
      liveRegion: false,
      child: RepaintBoundary(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _fill,
              // The petal SVG is built once and reused across frames; only its
              // position (driven by the fill) changes.
              child: SvgPicture.asset(
                'assets/branding/coin_petal.svg',
                width: _PetalTrack.petalSize,
              ),
              builder: (context, child) => _PetalTrack(
                fraction: _fill.value * _fillCeiling,
                width: AppSizing.loaderTrackWidth,
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
}

/// The shared progress track with a currency petal riding the leading edge of
/// the fill. The petal travels the full track width as [fraction] climbs 0..1,
/// so it reaches the far side exactly as the bar tops out.
class _PetalTrack extends StatelessWidget {
  const _PetalTrack({
    required this.fraction,
    required this.width,
    required this.petal,
  });

  final double fraction;
  final double width;
  final Widget petal;

  /// On-screen size of the riding petal.
  static const double petalSize = 30;

  /// Headroom above the track so the petal lifts off the bar instead of being
  /// clipped by it.
  static const double _lift = 16;

  @override
  Widget build(BuildContext context) {
    final value = fraction.clamp(0.0, 1.0);
    final travel = width - petalSize;
    final left = (value * travel).clamp(0.0, travel);
    return SizedBox(
      width: width,
      height: AppSizing.progressTrackHeight + _lift,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The bar itself, pinned to the bottom of the reserved box.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: PondProgressTrack(fraction: value, width: width),
          ),
          // The petal, straddling the fill's leading edge and lifted above it.
          Positioned(
            left: left,
            top: 0,
            child: IgnorePointer(child: petal),
          ),
        ],
      ),
    );
  }
}
