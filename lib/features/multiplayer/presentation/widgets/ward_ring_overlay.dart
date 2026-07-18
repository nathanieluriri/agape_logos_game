import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design/motion/curves.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/durations.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/spacing.dart';

/// The combo_lock ward: a soft luminous ring around the whole play area that
/// wards off Word Steal specifically for its window (it does not block
/// letter_freeze, fog_bank, or scramble). Rising edge: the ring draws
/// itself in. Live: a STATIC stroke (no ticker); a one-shot [Timer] fades it
/// at [wardUntil] (same pattern as the fog overlay's reduced-motion path).
/// A [pingTick] increment plays one ripple pulse (an attack just bounced) as
/// an INDEPENDENT layer on top of the base ring, which never remounts or
/// re-animates while a ping starts or ends.
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

/// True when [warded] is currently in effect: not expired per [now].
bool _isLive(bool warded, DateTime? until, DateTime now) =>
    warded && until != null && now.isBefore(until);

class _WardRingOverlayState extends State<WardRingOverlay> {
  Timer? _expiry;
  bool _fadingOut = false;
  bool _pinging = false;

  /// True once the draw-in has fully swept and settled. While true, the base
  /// ring renders as a plain, non-animated `CustomPaint` (no
  /// `TweenAnimationBuilder`, no ticker) - a ping starting or ending never
  /// touches this branch, so the base ring paints byte-identically
  /// throughout a ping instead of re-running the draw-in.
  bool _settled = false;

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

  bool get _live => _isLive(widget.warded, widget.wardUntil, widget.now());

  @override
  void initState() {
    super.initState();
    _armExpiry(risingEdge: true);
  }

  @override
  void didUpdateWidget(WardRingOverlay old) {
    super.didUpdateWidget(old);
    if (old.wardUntil != widget.wardUntil || old.warded != widget.warded) {
      final now = widget.now();
      final wasLive = _isLive(old.warded, old.wardUntil, now);
      final isLive = _isLive(widget.warded, widget.wardUntil, now);
      // Only a genuine rising edge (not live -> live) replays the draw-in;
      // extending an already-live ward's wardUntil (stacking another cast)
      // must leave the settled ring exactly where it is.
      _armExpiry(risingEdge: !wasLive && isLive);
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

  void _armExpiry({required bool risingEdge}) {
    _expiry?.cancel();
    _expiry = null;
    _fadingOut = false;
    _fadeSeq++; // Invalidate any in-flight fade-clear callback from before.
    _pinging = false;
    _pingSeq++; // Invalidate any in-flight ping-clear callback from before.
    if (risingEdge) _settled = false;
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

    Widget base;
    if (_fadingOut && !reduceMotion) {
      base = TweenAnimationBuilder<double>(
        key: const ValueKey<String>('ward-out'),
        tween: Tween(begin: 1, end: 0),
        duration: AppDurations.effectExpire,
        curve: AppCurves.exit,
        builder: (_, sweep, _) => CustomPaint(
          size: Size.infinite,
          painter: _WardPainter(sweep: sweep, stacks: stacks),
        ),
      );
    } else if (reduceMotion) {
      base = CustomPaint(
        size: Size.infinite,
        painter: _WardPainter(
          sweep: _fadingOut ? 0 : 1,
          stacks: stacks,
        ),
      );
    } else if (_settled) {
      // Fully drawn and at rest: a plain, non-animated CustomPaint - no
      // TweenAnimationBuilder, no ticker, no per-frame cost. A deflect ping
      // is a SEPARATE layer stacked on top (below), so this branch never
      // changes while a ping starts or ends: the base ring stays
      // byte-identical (sweep == 1) throughout.
      base = CustomPaint(
        size: Size.infinite,
        painter: _WardPainter(sweep: 1, stacks: stacks),
      );
    } else {
      // Draw-in on arrival; only entered right after `_armExpiry` has reset
      // `_settled = false` on a genuine rising edge. `onEnd` flips to the
      // static settled branch once the sweep completes, so the ring never
      // keeps a ticker running once fully drawn - and, because the settled
      // branch above is gated purely on `_settled` (not on which branch was
      // active last), a ping starting or ending later can never flip back
      // into this draw-in branch and replay the sweep.
      base = TweenAnimationBuilder<double>(
        key: const ValueKey<String>('ward-in'),
        tween: Tween(begin: 0, end: 1),
        duration: AppDurations.effectLand,
        curve: AppCurves.enter,
        onEnd: () {
          if (mounted) setState(() => _settled = true);
        },
        builder: (_, sweep, _) => CustomPaint(
          size: Size.infinite,
          painter: _WardPainter(sweep: sweep, stacks: stacks),
        ),
      );
    }

    // The deflect echo: an independent layer painted on top of the base
    // ring, never the base ring's own element. Phase-keyed by the actual
    // tick value: a plain constant key would still restart the ripple
    // correctly on the FIRST ping, but two pings in a row (widget.pingTick
    // advancing again while `_pinging` is already true) would rebuild the
    // SAME element in place with an unchanged Tween(begin:0,end:1) shape, so
    // forEachTween would see no target change and the second ping would
    // never actually restart. Keying by the tick forces a fresh element
    // every time. Never mounted under reduced motion.
    final showEcho = _pinging && !reduceMotion;

    return IgnorePointer(
      child: Semantics(
        label: 'Warded against Word Steal',
        child: RepaintBoundary(
          child: Stack(
            // Always a Stack, even with a single child: keeping the tree
            // shape constant (base always at the same slot) means the echo
            // layer appearing/disappearing never disturbs the base layer's
            // element, which is the whole point of this structure.
            fit: StackFit.expand,
            children: [
              base,
              if (showEcho)
                TweenAnimationBuilder<double>(
                  key: ValueKey<String>('ward-ping-${widget.pingTick}'),
                  tween: Tween(begin: 0, end: 1),
                  duration: AppDurations.effectExpire,
                  curve: AppCurves.exit,
                  builder: (_, ping, _) => CustomPaint(
                    size: Size.infinite,
                    painter: _WardEchoPainter(ping: ping),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints the base ring only. [sweep] 0..1 draws the ring's arc length.
class _WardPainter extends CustomPainter {
  const _WardPainter({required this.sweep, required this.stacks});

  final double sweep;
  final int stacks;

  @override
  void paint(Canvas canvas, Size size) {
    if (sweep <= 0) return;
    final rect = Offset.zero & size;
    final inset = rect.deflate(AppSpacing.sm);
    final rrect = RRect.fromRectAndRadius(
      inset,
      const Radius.circular(AppRadii.lg),
    );
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
  }

  @override
  bool shouldRepaint(_WardPainter old) =>
      old.sweep != sweep || old.stacks != stacks;
}

/// Paints the deflect echo only: a brighter ring expanding just outside the
/// base ring's outline as [ping] runs 0..1. Kept as its own painter (rather
/// than a second field on [_WardPainter]) so the echo is a genuinely
/// independent paint layer that never causes the base ring to repaint or
/// remount when a ping starts or ends.
class _WardEchoPainter extends CustomPainter {
  const _WardEchoPainter({required this.ping});

  final double ping;

  @override
  void paint(Canvas canvas, Size size) {
    if (ping <= 0 || ping >= 1) return;
    final rect = Offset.zero & size;
    final inset = rect.deflate(AppSpacing.sm);
    final rrect = RRect.fromRectAndRadius(
      inset,
      const Radius.circular(AppRadii.lg),
    );
    canvas.drawRRect(
      rrect.inflate(10 * ping),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.accent.withValues(alpha: 0.8 * (1 - ping)),
    );
  }

  @override
  bool shouldRepaint(_WardEchoPainter old) => old.ping != ping;
}
