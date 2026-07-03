// lib/shared/widgets/pond_loader.dart
import 'package:flutter/widgets.dart';

import '../../core/design/motion/curves.dart';
import '../../core/design/tokens/durations.dart';
import '../../core/design/tokens/sizing.dart';
import 'lily_pad.dart';

/// Calm pond loading indicator: a smooth teal lily pad bobbing gently on the
/// water. The app-wide stand-in for a progress spinner; sits perfectly still
/// when the platform asks for reduced motion.
class PondLoader extends StatefulWidget {
  const PondLoader({
    super.key,
    this.size = AppSizing.loader,
    this.label = 'Loading',
  });

  /// Diameter of the bobbing pad.
  final double size;

  /// Accessibility label announced for the loader.
  final String label;

  @override
  State<PondLoader> createState() => _PondLoaderState();
}

class _PondLoaderState extends State<PondLoader>
    with SingleTickerProviderStateMixin {
  /// Bob travel in logical pixels (matches the lily pad button idle bob).
  static const double _travel = 5;

  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: AppDurations.slow * 2,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _idle.stop();
      _idle.value = 0;
    } else if (!_idle.isAnimating) {
      _idle.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      liveRegion: false,
      // The boundary keeps the endless bob from repainting the whole page.
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _idle,
          builder: (context, child) {
            final dy = -_travel * AppCurves.float.transform(_idle.value);
            return Transform.translate(offset: Offset(0, dy), child: child);
          },
          child: LilyPad(
            size: widget.size,
            palette: LilyPadPalette.teal,
            shape: PadShape.smooth,
          ),
        ),
      ),
    );
  }
}
