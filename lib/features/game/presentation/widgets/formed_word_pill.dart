import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design/motion/curves.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/durations.dart';
import '../../../../core/design/tokens/gradients.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/shadows.dart';
import '../../../../core/design/tokens/sizing.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../core/design/tokens/typography.dart';

const BoxDecoration _pillDecoration = BoxDecoration(
  gradient: AppGradients.lilyGreen,
  borderRadius: AppRadii.pill,
  border: Border.fromBorderSide(
    BorderSide(color: AppColors.plusButtonBorder, width: 2),
  ),
  boxShadow: AppShadows.pill,
);

// PLAN: keeping letterSpacing: 2 on each per-letter Text approximates the
// old single-Text kerning; formed_word_pill.png may shift by sub-pixels. If
// the letters read too tight or loose on-device, adjust letterSpacing here.
const TextStyle _letterStyle = TextStyle(
  fontSize: 22,
  fontWeight: FontWeight.w700,
  letterSpacing: 2,
  color: AppColors.padLabel,
);

// Issue #63: the rejected-word cue reuses the app's danger palette (the same
// fill/border/foreground trio as ReconnectingBanner and MatchTimer's urgent
// state) so a rejection reads as a recognizable "danger" pill rather than an
// invented one-off color.
const BoxDecoration _rejectedDecoration = BoxDecoration(
  color: AppColors.dangerFill,
  borderRadius: AppRadii.pill,
  border: Border.fromBorderSide(
    BorderSide(color: AppColors.dangerBorder, width: 2),
  ),
);

/// A one-shot alert for [FormedWordPill] to flash (issue #63): the pill
/// shakes and turns red for a beat, showing [message], whenever a NEW
/// instance arrives whose [nonce] differs from the previous one. Callers bump
/// the nonce on every rejection (even a repeat of the same message) so
/// back-to-back identical rejections each get their own cue.
@immutable
class FormedWordAlert {
  const FormedWordAlert({required this.message, required this.nonce});

  final String message;
  final int nonce;
}

/// The in-progress word shown above the wheel while dragging: a lily-green
/// capsule floating on the water. Each letter pops in as it is added (a
/// left-to-right build), and the whole capsule fades as it appears and clears.
///
/// When [alert] carries a fresh [FormedWordAlert] (a rejected word), the
/// capsule instead shakes and flashes red with the alert's message for
/// [AppDurations.wordRejectFlash] before reverting to the normal display, so
/// a rejected word is never silent (issue #63: haptics alone give no signal
/// at all on web).
class FormedWordPill extends StatefulWidget {
  const FormedWordPill({super.key, required this.word, this.alert});

  final String word;

  /// A rejected-word cue to flash over the normal letter display. See
  /// [FormedWordAlert].
  final FormedWordAlert? alert;

  @override
  State<FormedWordPill> createState() => _FormedWordPillState();
}

class _FormedWordPillState extends State<FormedWordPill>
    with SingleTickerProviderStateMixin {
  // Created lazily on the first alert: a pill that never shows a rejection
  // never pays for a ticker. Kept NULLABLE (not `late final`) so dispose does
  // not construct a controller during unmount (an unsafe TickerMode ancestor
  // lookup on a deactivated element). Read through [_shake]; dispose through [_s].
  AnimationController? _s;
  AnimationController get _shake => _s ??= AnimationController(
    vsync: this,
    duration: AppDurations.wordRejectFlash,
  );
  Timer? _holdTimer;
  FormedWordAlert? _activeAlert;

  @override
  void didUpdateWidget(covariant FormedWordPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    final alert = widget.alert;
    if (alert == null) return;
    if (oldWidget.alert != null && oldWidget.alert!.nonce == alert.nonce) {
      return; // same one-shot signal already handled
    }
    _activeAlert = alert;
    _holdTimer?.cancel();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      // Reduced motion: snap to the flash's end state (no shake), but still
      // show the red pill + message so the signal is not lost entirely.
      _shake.stop();
    } else {
      _shake
        ..stop()
        ..reset()
        ..forward();
    }
    _holdTimer = Timer(AppDurations.wordRejectFlash, () {
      if (mounted) setState(() => _activeAlert = null);
    });
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _s?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final alert = _activeAlert;
    if (alert != null) {
      return AnimatedBuilder(
        animation: _shake,
        builder: (context, child) {
          final double decay = 1 - _shake.value;
          // Decaying side-to-side wobble: a handful of shrinking swings that
          // settle back to center by the time the controller completes.
          final double dx = reduceMotion
              ? 0
              : math.sin(_shake.value * math.pi * 6) * 8 * decay;
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: _RejectedWordPill(message: alert.message),
      );
    }
    return AnimatedOpacity(
      opacity: widget.word.isEmpty ? 0 : 1,
      duration: reduceMotion ? Duration.zero : AppDurations.fast,
      child: widget.word.isEmpty
          ? const SizedBox(height: AppSizing.pillHeight)
          : Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: _pillDecoration,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < widget.word.length; i++)
                    _PillLetter(
                      // Keyed by position so only the newly appended letter
                      // pops; letters already on screen keep their place.
                      key: ValueKey<int>(i),
                      char: widget.word[i],
                      animate: !reduceMotion,
                    ),
                ],
              ),
            ),
    );
  }
}

/// A single capsule letter that pops in the first time it appears.
class _PillLetter extends StatelessWidget {
  const _PillLetter({super.key, required this.char, required this.animate});

  final String char;
  final bool animate;

  /// Scale the letter pops in from (the overshoot comes from the curve).
  static const double _popFrom = 0.4;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: _popFrom, end: 1),
      duration: animate ? AppDurations.instant : Duration.zero,
      curve: AppCurves.pop,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Text(char, style: _letterStyle),
    );
  }
}

/// The red flash shown in place of the letters while a rejection alert is
/// active (issue #63). Mirrors the accepted-word pill's own container
/// (padding + decoration, no forced size) so it shrink-wraps to the message
/// the same way the letter capsule shrink-wraps to the word.
class _RejectedWordPill extends StatelessWidget {
  const _RejectedWordPill({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: _rejectedDecoration,
      child: Text(
        message,
        style: AppTypography.bannerSub.copyWith(color: AppColors.dangerOnPond),
      ),
    );
  }
}
