import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design/motion/curves.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/durations.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/spacing.dart';

/// A countdown to [endsAt] against the page-fed [nowMillis] clock. Formats
/// `m:ss` under an hour, `h:mm` over (async matches run up to 6 hours);
/// turns urgent under thirty seconds.
///
/// The time-boost moment: when [endsAt] GROWS (a banked bonus extended my
/// deadline), the displayed time does not snap. It rolls upward from the old
/// remaining time to the new one over [AppDurations.timeBoostClimb] while the
/// pill swells with a gold glow and a floating `+Ns` tag rises off it. If the
/// pill was urgent-red and the boost clears the threshold, the calm styling
/// returns as the displayed time passes it. Reduced motion: snap, no tag.
class MatchTimer extends StatefulWidget {
  const MatchTimer({super.key, required this.endsAt, required this.nowMillis});

  final int endsAt;
  final int nowMillis;

  @override
  State<MatchTimer> createState() => _MatchTimerState();
}

class _MatchTimerState extends State<MatchTimer>
    with SingleTickerProviderStateMixin {
  static const int _urgentThresholdSec = 30;
  static const int _hourInSec = 3600;

  late final AnimationController _climb = AnimationController(
    vsync: this,
    duration: AppDurations.timeBoostClimb,
  );

  /// The deadline the climb is rolling FROM (the pre-boost endsAt).
  int _fromEndsAt = 0;

  /// Whole seconds the current climb added (drives the `+Ns` tag).
  int _boostSec = 0;

  @override
  void initState() {
    super.initState();
    _fromEndsAt = widget.endsAt;
  }

  @override
  void didUpdateWidget(MatchTimer old) {
    super.didUpdateWidget(old);
    final grewMs = widget.endsAt - old.endsAt;
    final hadTimeLeft = old.endsAt > widget.nowMillis;
    if (grewMs >= 1000 && hadTimeLeft) {
      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (reduceMotion) {
        _fromEndsAt = widget.endsAt;
        return;
      }
      // A boost mid-climb re-anchors from the currently DISPLAYED deadline,
      // so back-to-back casts keep climbing instead of jumping.
      _fromEndsAt = _displayedEndsAt(old.endsAt);
      _boostSec = ((widget.endsAt - _fromEndsAt) / 1000).round();
      _climb.forward(from: 0);
    } else if (widget.endsAt != old.endsAt) {
      _fromEndsAt = widget.endsAt;
    }
  }

  int _displayedEndsAt(int targetEndsAt) {
    if (!_climb.isAnimating) return targetEndsAt;
    final t = AppCurves.climb.transform(_climb.value);
    return (_fromEndsAt + (targetEndsAt - _fromEndsAt) * t).round();
  }

  @override
  void dispose() {
    _climb.dispose();
    super.dispose();
  }

  String _label(int totalSec) => totalSec >= _hourInSec
      ? '${totalSec ~/ _hourInSec}h ${((totalSec % _hourInSec) ~/ 60).toString().padLeft(2, '0')}m'
      : '${totalSec ~/ 60}:${(totalSec % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _climb,
      builder: (context, _) {
        final displayEndsAt = _displayedEndsAt(widget.endsAt);
        final remainingMs =
            (displayEndsAt - widget.nowMillis).clamp(0, 1 << 31);
        final totalSec = remainingMs ~/ 1000;
        final urgent = totalSec <= _urgentThresholdSec;
        final climbing = _climb.isAnimating;
        // Swell peaks mid-climb, settles back by the end.
        final swell =
            climbing ? 1 + 0.15 * math.sin(math.pi * _climb.value) : 1.0;

        final pill = Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: urgent ? AppColors.dangerFill : AppColors.pillFill,
            borderRadius: AppRadii.pill,
            border: Border.all(
              color: climbing
                  ? AppColors.accent
                  : (urgent
                      ? AppColors.dangerBorder
                      : AppColors.settingsBorder),
            ),
            boxShadow: climbing
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(
                        alpha: 0.5 * math.sin(math.pi * _climb.value),
                      ),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Text(
            _label(totalSec),
            style: TextStyle(
              color: climbing
                  ? AppColors.accent
                  : (urgent ? AppColors.dangerOnPond : AppColors.pillText),
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
        );

        return RepaintBoundary(
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Transform.scale(scale: swell, child: pill),
              if (climbing)
                Positioned(
                  top: -18 - 14 * _climb.value,
                  child: FadeTransition(
                    opacity: ReverseAnimation(_climb),
                    child: Text(
                      '+${_boostSec}s',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
