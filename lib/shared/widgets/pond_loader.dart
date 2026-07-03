// lib/shared/widgets/pond_loader.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/design/motion/curves.dart';
import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/durations.dart';
import '../../core/design/tokens/gradients.dart';
import '../../core/design/tokens/radii.dart';
import '../../core/design/tokens/shadows.dart';
import '../../core/design/tokens/sizing.dart';
import '../../core/design/tokens/spacing.dart';
import 'lotus_mark.dart';
import 'pond_progress_track.dart';

/// Which surface the loader is standing in for. Each theme shows a distinct
/// emblem above the shared progress track so a load never reads as a blank,
/// anonymous wait.
enum PondLoaderTheme { puzzle, auth, settings, store }

/// Determinate pond loading indicator: a themed emblem, a lime-gold progress
/// track that fills on an estimate, and a label with a live percentage. The
/// bar keeps climbing (decelerating toward, but never claiming, full) so the
/// player can see the page is working rather than staring at a floating blob.
/// Sits still and shows a steady partial fill when reduced motion is asked for.
class PondLoader extends StatefulWidget {
  const PondLoader({
    super.key,
    this.theme = PondLoaderTheme.puzzle,
    this.label = 'Loading',
  });

  /// Chooses the emblem shown above the track.
  final PondLoaderTheme theme;

  /// Text shown beneath the track (also the accessibility label).
  final String label;

  @override
  State<PondLoader> createState() => _PondLoaderState();
}

class _PondLoaderState extends State<PondLoader>
    with SingleTickerProviderStateMixin {
  /// The bar eases toward this ceiling but never reaches 1.0, so it never
  /// claims "done" while a load is still in flight.
  static const double _fillCeiling = 0.99;

  /// Where the bar rests when reduced motion is requested (a calm ~70%).
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
    return Semantics(
      label: widget.label,
      liveRegion: false,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _fill,
          builder: (context, _) {
            final fraction = _fill.value * _fillCeiling;
            final percent = (fraction * 100).round();
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: AppSizing.loaderEmblem,
                  child: Center(child: _LoaderEmblem(theme: widget.theme)),
                ),
                const SizedBox(height: AppSpacing.lg),
                PondProgressTrack(
                  fraction: fraction,
                  width: AppSizing.loaderTrackWidth,
                ),
                const SizedBox(height: AppSpacing.sm),
                ExcludeSemantics(
                  child: _LoaderCaption(label: widget.label, percent: percent),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Label plus the live percentage, stacked and centered.
class _LoaderCaption extends StatelessWidget {
  const _LoaderCaption({required this.label, required this.percent});

  final String label;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.labelLarge;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: base?.copyWith(color: AppColors.padLabel)),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          '$percent%',
          style: base?.copyWith(
            color: AppColors.padLabelSoft,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

/// The per-surface emblem. Identity marks, deliberately calm: the filling track
/// carries the sense of motion.
class _LoaderEmblem extends StatelessWidget {
  const _LoaderEmblem({required this.theme});

  final PondLoaderTheme theme;

  static const double _lotusWidth = 120;
  static const double _gearSize = 46;
  static const double _coinSize = 56;

  @override
  Widget build(BuildContext context) {
    switch (theme) {
      case PondLoaderTheme.auth:
        return const LotusMark(width: _lotusWidth);
      case PondLoaderTheme.store:
        return SvgPicture.asset(
          'assets/branding/coin_petal.svg',
          width: _coinSize,
        );
      case PondLoaderTheme.settings:
        return const Icon(
          Icons.settings,
          size: _gearSize,
          color: AppColors.padLabelSoft,
        );
      case PondLoaderTheme.puzzle:
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MiniTile('Z'),
            SizedBox(width: AppSpacing.xs),
            _MiniTile('E'),
            SizedBox(width: AppSpacing.xs),
            _MiniTile('N'),
          ],
        );
    }
  }
}

/// A single mini lily-pad tile, echoing the word board's filled cells.
class _MiniTile extends StatelessWidget {
  const _MiniTile(this.letter);

  final String letter;

  static const double _size = 30;
  static const double _letterSize = 15;

  static const _decoration = BoxDecoration(
    gradient: AppGradients.lilyGreen,
    borderRadius: AppRadii.card,
    boxShadow: AppShadows.pad,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: _decoration,
      child: Text(
        letter,
        style: const TextStyle(
          color: AppColors.padLabel,
          fontWeight: FontWeight.w800,
          fontSize: _letterSize,
        ),
      ),
    );
  }
}
