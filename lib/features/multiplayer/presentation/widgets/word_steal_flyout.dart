import 'package:flutter/material.dart';

import '../../../../core/design/motion/curves.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/durations.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/spacing.dart';

/// A stolen word in flight. On the victim's screen it peels away from the
/// board toward the opponent's HUD corner; on the caster's screen it flies
/// into their score. Purely visual (the doc/rack already carry the truth);
/// self-removing overlay like [PowerupCastFlyout].
class WordStealFlyout {
  const WordStealFlyout._();

  static void show(
    BuildContext context, {
    required String label,
    required Offset from,
    required Offset to,
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _WordStealFlyoutView(
        label: label, from: from, to: to, onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _WordStealFlyoutView extends StatefulWidget {
  const _WordStealFlyoutView({
    required this.label,
    required this.from,
    required this.to,
    required this.onDone,
  });

  final String label;
  final Offset from;
  final Offset to;
  final VoidCallback onDone;

  @override
  State<_WordStealFlyoutView> createState() => _WordStealFlyoutViewState();
}

class _WordStealFlyoutViewState extends State<_WordStealFlyoutView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.stealFlight,
  )
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDone();
    })
    ..forward();

  late final Animation<double> _t =
      CurvedAnimation(parent: _controller, curve: AppCurves.emphasized);
  late final Animation<double> _fade = Tween<double>(begin: 1, end: 0).animate(
    CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1, curve: Curves.easeIn),
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        final t = _t.value;
        // A slight arc: bow the path upward at its midpoint.
        final pos = Offset.lerp(widget.from, widget.to, t)! +
            Offset(0, -60 * 4 * t * (1 - t));
        return Positioned(
          left: pos.dx,
          top: pos.dy,
          child: Transform.scale(scale: 1 - 0.4 * t, child: child),
        );
      },
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _fade,
          child: RepaintBoundary(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.pillFill,
                borderRadius: AppRadii.pill,
                border: Border.all(color: AppColors.pillBorder),
              ),
              child: Text(
                widget.label,
                style: const TextStyle(
                  color: AppColors.pillText,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
