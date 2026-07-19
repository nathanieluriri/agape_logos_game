import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design/motion/curves.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/durations.dart';
import '../../../../core/design/tokens/sizing.dart';
import '../../../game/presentation/widgets/letter_wheel.dart';

/// Frost over each frozen wheel node with a full life cycle: the frost CREEPS
/// over the tile when a freeze lands, rests as a static rimmed disc (no
/// ticker), and SHATTERS when the freeze lapses. The match page recomputes
/// [frozenSlots] against its ticker; this widget diffs successive sets to
/// know which slot just froze or thawed. Reduced motion: static disc, no
/// creep, no shatter.
class FrozenLetterOverlay extends StatefulWidget {
  const FrozenLetterOverlay({
    super.key,
    required this.frozenSlots,
    required this.letterCount,
    required this.size,
    this.stacks = 1,
  });

  /// Wheel SLOT indices (not rack letter indices) currently frozen.
  final Set<int> frozenSlots;
  final int letterCount;
  final Size size;

  /// Live freeze count (Project B intensity hook): deeper tint at 2+.
  final int stacks;

  @override
  State<FrozenLetterOverlay> createState() => _FrozenLetterOverlayState();
}

class _FrozenLetterOverlayState extends State<FrozenLetterOverlay> {
  /// Slots mid-shatter, kept on screen until their exit window elapses.
  final Set<int> _shattering = <int>{};

  @override
  void didUpdateWidget(FrozenLetterOverlay old) {
    super.didUpdateWidget(old);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) return;
    for (final slot in old.frozenSlots) {
      if (!widget.frozenSlots.contains(slot) && _shattering.add(slot)) {
        Future<void>.delayed(AppDurations.effectExpire, () {
          if (mounted) setState(() => _shattering.remove(slot));
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final live = widget.frozenSlots;
    if (live.isEmpty && _shattering.isEmpty) return const SizedBox.shrink();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final centers = LetterWheel.centersIn(widget.size, widget.letterCount);
    const node = AppSizing.wheelNode;
    return IgnorePointer(
      child: RepaintBoundary(
        child: Stack(
          children: [
            for (final slot in {...live, ..._shattering})
              if (slot >= 0 && slot < centers.length)
                Positioned(
                  left: centers[slot].dx - node / 2,
                  top: centers[slot].dy - node / 2,
                  width: node,
                  height: node,
                  child: _FrostDisc(
                    // Keyed per slot so the disc's identity (and its
                    // _shattering membership) survives across rebuilds; the
                    // creep/shatter phase itself is keyed separately below.
                    key: ValueKey<int>(slot),
                    leaving: !live.contains(slot),
                    reduceMotion: reduceMotion,
                    stacks: math.max(1, widget.stacks),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// One node's frost: creep in (0..1), rest static, shatter out (0..1).
class _FrostDisc extends StatelessWidget {
  const _FrostDisc({
    super.key,
    required this.leaving,
    required this.reduceMotion,
    required this.stacks,
  });

  final bool leaving;
  final bool reduceMotion;
  final int stacks;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion) {
      return _frostBody(creep: 1, shatter: 0);
    }
    if (leaving) {
      // Phase-keyed: without this, flipping `leaving` reuses the creep
      // TweenAnimationBuilder's element (same type, no key). Both phases'
      // tweens end at 1, so ImplicitlyAnimatedWidgetState's forEachTween
      // sees no target change and never restarts the controller: the
      // shatter's t stays pinned at the creep's already-settled 1, and
      // `_frostBody(creep: 1, shatter: 1)` (fade == 0) paints nothing for
      // the whole exit window. A distinct key per phase forces a fresh
      // element/controller so the shatter actually sweeps 0 -> 1.
      return TweenAnimationBuilder<double>(
        key: const ValueKey<bool>(true),
        tween: Tween(begin: 0, end: 1),
        duration: AppDurations.effectExpire,
        curve: AppCurves.exit,
        builder: (_, t, _) => _frostBody(creep: 1, shatter: t),
      );
    }
    return TweenAnimationBuilder<double>(
      key: const ValueKey<bool>(false),
      tween: Tween(begin: 0, end: 1),
      duration: AppDurations.effectLand,
      curve: AppCurves.enter,
      builder: (_, t, _) => _frostBody(creep: t, shatter: 0),
    );
  }

  Widget _frostBody({required double creep, required double shatter}) {
    return CustomPaint(
      painter: _FrostPainter(creep: creep, shatter: shatter, stacks: stacks),
      child: Center(
        child: Icon(
          Icons.ac_unit_rounded,
          color: AppColors.frostBorder,
          size: 24 * creep * (1 - shatter),
        ),
      ),
    );
  }
}

/// Painter-based frost (no shader, no new font glyphs): a translucent disc
/// that grows with [creep], six crystal spokes, and on [shatter] a burst of
/// falling shards. All geometry derives from the node size at paint time; no
/// allocation is retained across frames beyond the const paints.
class _FrostPainter extends CustomPainter {
  const _FrostPainter({
    required this.creep,
    required this.shatter,
    required this.stacks,
  });

  final double creep;
  final double shatter;
  final int stacks;

  static const int _spokes = 6;
  static const int _shards = 6; // well under the 12-particle cap

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final fade = 1 - shatter;
    if (fade <= 0 || creep <= 0) return;

    // Deeper blue at 2+ stacks.
    final fillAlpha = (0.60 + 0.15 * (stacks - 1)).clamp(0.0, 0.9) * creep * fade;
    canvas.drawCircle(
      center,
      radius * creep,
      Paint()..color = AppColors.frostFill.withValues(alpha: fillAlpha),
    );
    final rim = Paint()
      ..color = AppColors.frostBorder.withValues(alpha: 0.8 * creep * fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius * creep, rim);

    // Crystal spokes grow with the creep.
    for (var i = 0; i < _spokes; i++) {
      final dir = i * 2 * math.pi / _spokes + math.pi / 12;
      final tip = center + Offset.fromDirection(dir, radius * 0.85 * creep);
      canvas.drawLine(center, tip, rim);
    }

    // Shatter: shards fall away and fade.
    if (shatter > 0) {
      final shard = Paint()
        ..color = AppColors.frostBorder.withValues(alpha: 0.9 * fade);
      for (var i = 0; i < _shards; i++) {
        final dir = i * 2 * math.pi / _shards;
        final drift = Offset.fromDirection(dir, radius * 0.5 * shatter) +
            Offset(0, radius * 0.6 * shatter * shatter);
        canvas.drawCircle(center + drift, 3 * fade, shard);
      }
    }
  }

  @override
  bool shouldRepaint(_FrostPainter old) =>
      old.creep != creep || old.shatter != shatter || old.stacks != stacks;
}
