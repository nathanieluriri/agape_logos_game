import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/durations.dart';

/// Delivery state of the wallet/progress shown beside the petal amount and the
/// level label: the message-tick idea (WhatsApp/Telegram) applied to updates.
///
/// * [syncing]  means the value on screen includes local-only changes that
///   have not reached the server yet. Rendered as a small ticking clock.
/// * [synced]   means the server just confirmed the queued changes. Rendered
///   as a green tick that lingers briefly, then settles to nothing.
/// * [failed]   means a queued change permanently failed to reach the cloud.
///   Rendered as an amber alert dot.
/// * [none]     means local and server agree; nothing is drawn.
enum SyncBadgeStatus { none, syncing, synced, failed }

/// The badge itself: pure and provider-free (like every shared widget), sized
/// to sit inline beside pill text without shifting layout when it disappears.
class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({super.key, required this.status, this.size = 12});

  final SyncBadgeStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppDurations.fast,
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: switch (status) {
        SyncBadgeStatus.none => SizedBox(key: const ValueKey('none'), width: 0, height: size),
        SyncBadgeStatus.syncing => _SyncingClock(key: const ValueKey('syncing'), size: size),
        SyncBadgeStatus.synced => _ConfirmedTick(key: const ValueKey('synced'), size: size),
        SyncBadgeStatus.failed => _FailedDot(key: const ValueKey('failed'), size: size),
      },
    );
  }
}

/// Tiny clock with a sweeping hand (the Telegram "pending" read), painted with
/// tokens so it inherits the pond chrome.
class _SyncingClock extends StatefulWidget {
  const _SyncingClock({super.key, required this.size});

  final double size;

  @override
  State<_SyncingClock> createState() => _SyncingClockState();
}

class _SyncingClockState extends State<_SyncingClock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Syncing',
      child: AnimatedBuilder(
        animation: _spin,
        builder: (context, _) => CustomPaint(
          size: Size.square(widget.size),
          painter: _ClockPainter(handTurns: _spin.value),
        ),
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  const _ClockPainter({required this.handTurns});

  /// Fraction of a full rotation for the minute hand (0..1).
  final double handTurns;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final stroke = math.max(1.2, size.width / 9);
    final paint = Paint()
      ..color = AppColors.syncPending
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - stroke / 2, paint);

    // Sweeping minute hand + a slow hour hand a quarter-turn behind.
    final minuteAngle = handTurns * 2 * math.pi - math.pi / 2;
    final hourAngle = (handTurns / 4) * 2 * math.pi - math.pi / 2;
    canvas
      ..drawLine(
        center,
        center + Offset.fromDirection(minuteAngle, radius * 0.62),
        paint,
      )
      ..drawLine(
        center,
        center + Offset.fromDirection(hourAngle, radius * 0.38),
        paint,
      );
  }

  @override
  bool shouldRepaint(covariant _ClockPainter old) =>
      old.handTurns != handTurns;
}

/// Green confirmation tick (the "delivered" read).
class _ConfirmedTick extends StatelessWidget {
  const _ConfirmedTick({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Synced',
      child: CustomPaint(
        size: Size.square(size),
        painter: const _TickPainter(),
      ),
    );
  }
}

class _TickPainter extends CustomPainter {
  const _TickPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = math.max(1.4, size.width / 7);
    final paint = Paint()
      ..color = AppColors.syncConfirmed
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(size.width * 0.14, size.height * 0.55)
      ..lineTo(size.width * 0.42, size.height * 0.82)
      ..lineTo(size.width * 0.88, size.height * 0.22);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TickPainter old) => false;
}

/// Amber "!" for a permanently failed sync (the home banner owns the retry).
class _FailedDot extends StatelessWidget {
  const _FailedDot({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Sync failed',
      child: CustomPaint(
        size: Size.square(size),
        painter: const _BangPainter(),
      ),
    );
  }
}

class _BangPainter extends CustomPainter {
  const _BangPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = math.max(1.4, size.width / 7);
    final paint = Paint()
      ..color = AppColors.syncFailed
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final cx = size.width / 2;
    canvas
      ..drawLine(
        Offset(cx, size.height * 0.12),
        Offset(cx, size.height * 0.58),
        paint,
      )
      ..drawCircle(
        Offset(cx, size.height * 0.86),
        stroke * 0.55,
        Paint()..color = AppColors.syncFailed,
      );
  }

  @override
  bool shouldRepaint(covariant _BangPainter old) => false;
}
