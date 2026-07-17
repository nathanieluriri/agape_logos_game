// lib/shared/widgets/pond_progress_track.dart
import 'package:flutter/widgets.dart';

import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/durations.dart';
import '../../core/design/tokens/gradients.dart';
import '../../core/design/tokens/shadows.dart';
import '../../core/design/tokens/sizing.dart';

/// The app's canonical progress track: a deep-water pill with a premium
/// lime-gold fill (lit crest at the leading edge + a glossy top surface). One
/// component, shared by the level-complete bar and the determinate loader, so
/// every filling bar in the app reads the same.
///
/// The static look is paint-only (tickerless). Pass [shimmer] to add a soft
/// sheen band that sweeps the filled portion for a "premium water" feel; it is
/// off by default so bars that do not need it stay cheap and settle in tests.
class PondProgressTrack extends StatelessWidget {
  const PondProgressTrack({
    super.key,
    required this.fraction,
    this.width = AppSizing.progressTrackWidth,
    this.height = AppSizing.progressTrackHeight,
    this.shimmer = false,
  });

  /// Fill amount in the range 0..1 (clamped defensively).
  final double fraction;
  final double width;
  final double height;

  /// When true, a continuous sheen sweeps the filled portion.
  final bool shimmer;

  // Pill geometry (named so the two callers stay identical).
  static const double _trackRadius = 14;
  static const double _fillRadius = 9;
  static const double _innerPad = 2;
  static const double _borderWidth = 2;

  @override
  Widget build(BuildContext context) {
    final value = fraction.clamp(0.0, 1.0);
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(_innerPad),
      decoration: BoxDecoration(
        color: AppColors.progressTrack,
        borderRadius: BorderRadius.circular(_trackRadius),
        border: Border.all(
          color: AppColors.progressTrackBorder,
          width: _borderWidth,
        ),
        boxShadow: AppShadows.track,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          // A hair of width at zero so the rounded cap is always visible.
          widthFactor: value <= 0 ? 0.0001 : value,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_fillRadius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1) Lime-gold base with the lit crest at the leading edge.
                const DecoratedBox(
                  decoration:
                      BoxDecoration(gradient: AppGradients.progressFillPremium),
                ),
                // 2) Glossy top-surface highlight (reads as lit water).
                const DecoratedBox(
                  decoration: BoxDecoration(gradient: AppGradients.progressGloss),
                ),
                // 3) Optional continuous sheen sweep.
                if (shimmer) const _SheenSweep(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A soft sheen band that sweeps across the filled portion. Clipped by the
/// caller's `ClipRRect`. Parks (no repaint) under reduced motion.
class _SheenSweep extends StatefulWidget {
  const _SheenSweep();

  @override
  State<_SheenSweep> createState() => _SheenSweepState();
}

class _SheenSweepState extends State<_SheenSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep =
      AnimationController(vsync: this, duration: AppDurations.progressShimmer);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _sweep.stop();
    } else if (!_sweep.isAnimating) {
      _sweep.repeat();
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _sweep,
        builder: (context, _) => FractionalTranslation(
          // Sweep from just off the left of the fill to just off the right.
          // PLAN: tune the -1.2..+1.2 travel + band stops so the highlight
          // glides once per loop and does not look like a hard bar.
          translation: Offset(-1.2 + _sweep.value * 2.4, 0),
          child: const DecoratedBox(
            decoration: BoxDecoration(gradient: AppGradients.progressSheen),
          ),
        ),
      ),
    );
  }
}
