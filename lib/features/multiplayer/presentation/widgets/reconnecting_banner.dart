import 'package:flutter/widgets.dart';

import '../../../../core/design/motion/curves.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/durations.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/spacing.dart';

/// Issue #61: the live board's Firestore listeners (`foundWords`/score/effect
/// updates) stop delivering while the device is offline, but the local timer
/// keeps ticking and letter selection stays enabled, so the board otherwise
/// looks live while it is actually stale. This is the signal that tells the
/// player the board may be behind - it does not itself block input (the match
/// page skips a doomed submit call while offline instead, see
/// `_MatchPageState._submit`).
///
/// Mounted only while `isOnlineProvider` reads false, and only in the
/// caller's live-play branch (never on the lobby/countdown interlude or the
/// finished/result screens), so it pops in and out with the offline window
/// rather than living for the whole match.
class ReconnectingBanner extends StatelessWidget {
  const ReconnectingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
      duration: reduceMotion ? Duration.zero : AppDurations.fast,
      curve: AppCurves.enter,
      builder: (_, t, child) => Transform.scale(scale: 0.92 + 0.08 * t, child: child),
      child: RepaintBoundary(
        child: Semantics(
          liveRegion: true,
          label: 'Reconnecting, you are offline',
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.dangerFill,
              borderRadius: AppRadii.card,
              border: Border.all(color: AppColors.dangerBorder),
            ),
            child: const Text(
              'Reconnecting... you are offline',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.dangerOnPond,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
