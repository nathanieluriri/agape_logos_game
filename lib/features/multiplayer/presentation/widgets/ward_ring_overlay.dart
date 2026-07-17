import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design/motion/curves.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/durations.dart';
import '../../../../core/design/tokens/spacing.dart';

/// The combo_lock ward: a soft luminous ring around the whole play area that
/// deflects incoming attacks for its window. Rising edge: the ring draws
/// itself in. Live: a STATIC stroke (no ticker); a one-shot [Timer] fades it
/// at [wardUntil] (same pattern as the fog overlay's reduced-motion path).
/// A [pingTick] increment plays one ripple pulse (an attack just bounced).
/// Distinct from the shield: the shield is a one-shot bubble on the wheel,
/// the ward is a timed perimeter around everything.
class WardRingOverlay extends StatefulWidget {
  const WardRingOverlay({
    super.key,
    required this.warded,
    required this.wardUntil,
    required this.now,
    this.pingTick = 0,
    this.stacks = 1,
  });

  final bool warded;
  final DateTime? wardUntil;
  final DateTime Function() now;

  /// Increments once per deflected attack; each increment pulses the ring.
  final int pingTick;

  /// Live ward count (Project B): brighter stroke at 2+.
  final int stacks;

  @override
  State<WardRingOverlay> createState() => _WardRingOverlayState();
}

class _WardRingOverlayState extends State<WardRingOverlay> {
  Timer? _expiry;
  bool _fadingOut = false;
  bool _pinging = false;

  /// Bumped every time [_armExpiry] runs (rising edge or any [wardUntil]
  /// change) and again when the expiry [Timer] actually starts a fade. Only
  /// the delayed fade-clear callback whose captured sequence still matches
  /// the current one is allowed to clear [_fadingOut]: a re-ward mid-fade
  /// resets [_fadingOut] synchronously AND arms a fresh cycle (with its own
  /// new sequence), so a stale callback from the superseded cycle can never
  /// reach in and cut a later fade short.
  int _fadeSeq = 0;

  /// Bumped on every ping tick (and invalidated by [_armExpiry], so a fresh
  /// ward cycle never inherits a leftover pulse from a previous one). Only
  /// the latest ping's delayed clear callback actually clears [_pinging],
  /// so a ping that lands while a previous one is still animating restarts
  /// cleanly instead of the earlier one's callback truncating it.
  int _pingSeq = 0;

  bool get _live {
    final until = widget.wardUntil;
    return widget.warded && until != null && widget.now().isBefore(until);
  }

  @override
  void initState() {
    super.initState();
    _armExpiry();
  }

  @override
  void didUpdateWidget(WardRingOverlay old) {
    super.didUpdateWidget(old);
    if (old.wardUntil != widget.wardUntil || old.warded != widget.warded) {
      _armExpiry();
    }
    if (widget.pingTick != old.pingTick && _live) {
      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (!reduceMotion) {
        _pingSeq++;
        final seq = _pingSeq;
        setState(() => _pinging = true);
        Future<void>.delayed(AppDurations.effectExpire, () {
          if (mounted && _pingSeq == seq) setState(() => _pinging = false);
        });
      }
    }
  }

  void _armExpiry() {
    _expiry?.cancel();
    _expiry = null;
    _fadingOut = false;
    _fadeSeq++; // Invalidate any in-flight fade-clear callback from before.
    _pinging = false;
    _pingSeq++; // Invalidate any in-flight ping-clear callback from before.
    final until = widget.wardUntil;
    if (!widget.warded || until == null) return;
    final delay = until.difference(widget.now());
    _expiry = Timer(delay.isNegative ? Duration.zero : delay, () {
      _expiry = null;
      if (!mounted) return;
      _fadeSeq++;
      final seq = _fadeSeq;
      setState(() => _fadingOut = true);
      Future<void>.delayed(AppDurations.effectExpire, () {
        if (mounted && _fadeSeq == seq) setState(() => _fadingOut = false);
      });
    });
  }

  @override
  void dispose() {
    _expiry?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_live && !_fadingOut) return const SizedBox.shrink();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final stacks = math.max(1, widget.stacks);

    Widget ring;
    if (_fadingOut && !reduceMotion) {
      ring = TweenAnimationBuilder<double>(
        key: const ValueKey<String>('ward-out'),
        tween: Tween(begin: 1, end: 0),
        duration: AppDurations.effectExpire,
        curve: AppCurves.exit,
        builder: (_, sweep, _) => CustomPaint(
          size: Size.infinite,
          painter: _WardPainter(sweep: sweep, ping: 0, stacks: stacks),
        ),
      );
    } else if (reduceMotion) {
      ring = CustomPaint(
        size: Size.infinite,
        painter: _WardPainter(
          sweep: _fadingOut ? 0 : 1,
          ping: 0,
          stacks: stacks,
        ),
      );
    } else if (_pinging) {
      // Phase-keyed by the actual tick value: a plain constant key would
      // still restart the ripple correctly on the FIRST flip into this
      // branch, but two pings in a row (widget.pingTick advancing again
      // while `_pinging` is already true) would rebuild the SAME element in
      // place with an unchanged Tween(begin:0,end:1) shape, so
      // forEachTween would see no target change and the second ping would
      // never actually restart the sweep. Keying by the tick forces a
      // fresh element every time.
      ring = TweenAnimationBuilder<double>(
        key: ValueKey<String>('ward-ping-${widget.pingTick}'),
        tween: Tween(begin: 0, end: 1),
        duration: AppDurations.effectExpire,
        curve: AppCurves.exit,
        builder: (_, ping, _) => CustomPaint(
          size: Size.infinite,
          painter: _WardPainter(sweep: 1, ping: ping, stacks: stacks),
        ),
      );
    } else {
      // Draw-in on arrival; TweenAnimationBuilder rests at the static final
      // frame with no ticker once the sweep completes. Phase-keyed: without
      // a distinct key here, flipping in from the fade-out or ping branch
      // above (same TweenAnimationBuilder<double> type at this slot) would
      // reuse that element in place instead of mounting a fresh one, and
      // the fade-out/ping branches share the same Tween shape family, so
      // forEachTween would see no target change and the sweep would stay
      // pinned at whatever value it last held instead of drawing in.
      ring = TweenAnimationBuilder<double>(
        key: const ValueKey<String>('ward-in'),
        tween: Tween(begin: 0, end: 1),
        duration: AppDurations.effectLand,
        curve: AppCurves.enter,
        builder: (_, sweep, _) => CustomPaint(
          size: Size.infinite,
          painter: _WardPainter(sweep: sweep, ping: 0, stacks: stacks),
        ),
      );
    }
    return IgnorePointer(child: RepaintBoundary(child: ring));
  }
}

/// [sweep] 0..1 draws the ring's arc length; [ping] 0..1 pulses a brighter,
/// slightly expanded echo ring outward.
class _WardPainter extends CustomPainter {
  const _WardPainter({
    required this.sweep,
    required this.ping,
    required this.stacks,
  });

  final double sweep;
  final double ping;
  final int stacks;

  @override
  void paint(Canvas canvas, Size size) {
    if (sweep <= 0) return;
    final rect = Offset.zero & size;
    final inset = rect.deflate(AppSpacing.sm);
    final rrect = RRect.fromRectAndRadius(inset, const Radius.circular(28));
    final alpha = (0.55 + 0.15 * (stacks - 1)).clamp(0.0, 0.85);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = AppColors.lilyGreenLight.withValues(alpha: alpha);

    if (sweep >= 1) {
      canvas.drawRRect(rrect, stroke);
    } else {
      // Partial draw-in: extract the leading portion of the outline path.
      final path = Path()..addRRect(rrect);
      for (final metric in path.computeMetrics()) {
        canvas.drawPath(
          metric.extractPath(0, metric.length * sweep),
          stroke,
        );
      }
    }
    // Gold glint riding the leading edge while drawing in.
    if (sweep < 1) {
      final path = Path()..addRRect(rrect);
      for (final metric in path.computeMetrics()) {
        final tangent = metric.getTangentForOffset(metric.length * sweep);
        if (tangent != null) {
          canvas.drawCircle(
            tangent.position,
            4,
            Paint()..color = AppColors.accent,
          );
        }
      }
    }
    // Deflect ping: a brighter echo expanding just outside the ring.
    if (ping > 0 && ping < 1) {
      canvas.drawRRect(
        rrect.inflate(10 * ping),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = AppColors.accent.withValues(alpha: 0.8 * (1 - ping)),
      );
    }
  }

  @override
  bool shouldRepaint(_WardPainter old) =>
      old.sweep != sweep || old.ping != ping || old.stacks != stacks;
}
