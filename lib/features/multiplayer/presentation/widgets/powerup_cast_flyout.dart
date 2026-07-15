import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/design/motion/curves.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/durations.dart';
import '../../domain/powerup_kind.dart';

/// The caster's half of the cast feedback loop: the chip a player just
/// dragged past the fire threshold scales up and flies off the top edge of
/// the screen. The victim's half is [PowerupIncomingBanner].
class PowerupCastFlyout {
  const PowerupCastFlyout._();

  /// Inserts a self-removing overlay entry above [context]'s nearest
  /// [Overlay], starting from the drag release point [from] (GLOBAL
  /// coordinates, matching [PowerupWheel.onFire]).
  static void show(BuildContext context, String kind, {required Offset from}) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) =>
          _PowerupCastFlyoutView(kind: kind, from: from, onDone: entry.remove),
    );
    overlay.insert(entry);
  }
}

class _PowerupCastFlyoutView extends StatefulWidget {
  const _PowerupCastFlyoutView({
    required this.kind,
    required this.from,
    required this.onDone,
  });

  final String kind;
  final Offset from;
  final VoidCallback onDone;

  @override
  State<_PowerupCastFlyoutView> createState() =>
      _PowerupCastFlyoutViewState();
}

class _PowerupCastFlyoutViewState extends State<_PowerupCastFlyoutView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _rise;
  late final Animation<double> _fade;

  static const double _chipSize = 48;
  static const double _riseDistance = 520;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: AppDurations.powerupCast)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) widget.onDone();
          })
          ..forward();
    _scale = Tween<double>(
      begin: 0.6,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: AppCurves.pop));
    _rise = Tween<double>(begin: 0, end: -_riseDistance).animate(
      CurvedAnimation(parent: _controller, curve: AppCurves.emphasized),
    );
    _fade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemId = powerupItemId(widget.kind) ?? widget.kind;
    return Positioned(
      left: widget.from.dx - _chipSize / 2,
      top: widget.from.dy - _chipSize / 2,
      width: _chipSize,
      height: _chipSize,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _fade,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, _rise.value),
              child: Transform.scale(scale: _scale.value, child: child),
            ),
            child: RepaintBoundary(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.pillFill,
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: AppColors.pillBorder),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: SvgPicture.asset(
                    'assets/powerups/$itemId.svg',
                    semanticsLabel: itemId,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
