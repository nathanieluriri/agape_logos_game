import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design/motion/curves.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/durations.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/glyphs/pond_glyph.dart';
import 'match_timer.dart';

/// Max height of the compact match top bar (design budget, Task 7).
const double kMatchHudHeight = 56;

/// The match page's whole top bar in one row: my score, a slim countdown
/// pill, a compact opponent chip, the dictionary button, and (async matches
/// only) a forfeit affordance. Replaces the oversized `_MyScore` /
/// `MatchTimer` / `OpponentHud` row, whose 22pt score column and full-size
/// opponent pill left barely any width for "You" to read as legible on a
/// narrow phone.
///
/// Owns its own countdown tick (the row does not depend on the page's clock):
/// only the timer pill rebuilds each tick, not the score or the opponent
/// chip.
class MatchHud extends StatelessWidget {
  const MatchHud({
    super.key,
    required this.myScore,
    required this.myWords,
    required this.opponentName,
    required this.opponentWords,
    required this.opponentConnected,
    required this.endsAt,
    required this.onDictionary,
    this.onForfeit,
    this.now,
    this.doublePoints = false,
    this.doubleStacks = 1,
  });

  final int myScore;
  final int myWords;
  final String opponentName;
  final int opponentWords;
  final bool opponentConnected;
  final DateTime endsAt;
  final VoidCallback onDictionary;

  /// Double points powerup active on my score. Wraps the score pip in a gold
  /// aura and an x2/x4 badge, and floats a doubled pop on each score gain.
  final bool doublePoints;

  /// Stacked double-points charges (2 stacks = x4). Matches
  /// `MatchActiveEffects.doublePointsStacks`.
  final int doubleStacks;

  /// Server-adjusted clock reader. Defaults to the raw device clock so
  /// existing callers that do not care about clock skew keep working; the
  /// match page passes `() => ref.read(serverClockProvider).now()` so the
  /// countdown expires on server time even if the device clock is behind.
  final DateTime Function()? now;

  /// Reuses the live match's `_confirmForfeit` + leave flow. Non-null only
  /// for async matches, whose back button pops freely: this is their only
  /// forfeit affordance. Null hides the affordance entirely (live matches
  /// keep their existing wheel-row flag instead).
  final VoidCallback? onForfeit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kMatchHudHeight,
      child: Row(
        children: [
          _MyScorePip(
            score: myScore,
            words: myWords,
            doublePoints: doublePoints,
            doubleStacks: doubleStacks,
          ),
          const SizedBox(width: AppSpacing.sm),
          _TickingTimer(endsAt: endsAt, now: now ?? DateTime.now),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _OpponentChip(
              name: opponentName,
              words: opponentWords,
              connected: opponentConnected,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          _HudIconButton(
            glyph: PondGlyph.book,
            semanticLabel: 'Dictionary',
            onTap: onDictionary,
          ),
          if (onForfeit != null)
            _HudIconButton(
              glyph: PondGlyph.swords,
              semanticLabel: 'Forfeit match',
              onTap: onForfeit!,
            ),
        ],
      ),
    );
  }
}

/// Ticks its own clock so the rest of the HUD row never rebuilds on the
/// match's 500ms tick, only this pill does.
class _TickingTimer extends StatefulWidget {
  const _TickingTimer({required this.endsAt, required this.now});

  final DateTime endsAt;

  /// Server-adjusted clock reader (see [MatchHud.now]).
  final DateTime Function() now;

  @override
  State<_TickingTimer> createState() => _TickingTimerState();
}

class _TickingTimerState extends State<_TickingTimer> {
  Timer? _timer;
  late int _now = widget.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      setState(() => _now = widget.now().millisecondsSinceEpoch);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MatchTimer(
    endsAt: widget.endsAt.millisecondsSinceEpoch,
    nowMillis: _now,
  );
}

/// "You" + my score. Under double points it wears a gold aura and an x2
/// badge, and each score gain floats a doubled pop ("+14 x2") off the pip.
class _MyScorePip extends StatefulWidget {
  const _MyScorePip({
    required this.score,
    required this.words,
    required this.doublePoints,
    required this.doubleStacks,
  });

  final int score;
  final int words;
  final bool doublePoints;
  final int doubleStacks;

  @override
  State<_MyScorePip> createState() => _MyScorePipState();
}

class _MyScorePipState extends State<_MyScorePip> {
  int? _popDelta;
  int _popSeq = 0;

  @override
  void didUpdateWidget(_MyScorePip old) {
    super.didUpdateWidget(old);
    final delta = widget.score - old.score;
    if (delta > 0 && widget.doublePoints) {
      setState(() {
        _popDelta = delta;
        _popSeq++;
      });
      final seq = _popSeq;
      Future<void>.delayed(AppDurations.effectLand, () {
        if (mounted && _popSeq == seq) setState(() => _popDelta = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final active = widget.doublePoints;
    final multiplier = math.pow(2, math.max(1, widget.doubleStacks)).toInt();

    final pip = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'You',
          style: TextStyle(color: AppColors.padLabelSoft, fontSize: 12),
        ),
        const SizedBox(width: AppSpacing.xs),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadii.pill,
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.45),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: Text(
            '${widget.score}',
            style: TextStyle(
              color: active ? AppColors.accent : AppColors.padLabel,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (active) ...[
          const SizedBox(width: AppSpacing.xxs),
          // Keyed constant: this subtree only exists while active (it lives
          // inside `if (active)`), so mounting IS activation. The tween runs
          // exactly once per activation and holds at 1.0 afterward, no
          // ticker left running.
          TweenAnimationBuilder<double>(
            key: const ValueKey('double-points-badge'),
            tween: Tween(begin: 0.6, end: 1),
            duration: reduceMotion ? Duration.zero : AppDurations.fast,
            curve: AppCurves.pop,
            builder: (_, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Text(
              'x$multiplier',
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ],
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        pip,
        if (_popDelta != null)
          Positioned(
            top: -16,
            left: 0,
            child: IgnorePointer(
              child: TweenAnimationBuilder<double>(
                key: ValueKey<int>(_popSeq),
                tween: Tween(begin: 0, end: 1),
                duration:
                    reduceMotion ? Duration.zero : AppDurations.effectLand,
                curve: AppCurves.enter,
                builder: (_, t, child) => Transform.translate(
                  offset: Offset(0, -10 * t),
                  child: child,
                ),
                child: Text(
                  '+$_popDelta x$multiplier',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The opponent's compact chip: presence dot, ellipsized name, word count.
/// All values come from the match doc (server-authoritative).
class _OpponentChip extends StatelessWidget {
  const _OpponentChip({
    required this.name,
    required this.words,
    required this.connected,
  });

  final String name;
  final int words;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.pillFill,
        borderRadius: AppRadii.pill,
        border: Border.all(color: AppColors.pillBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            connected ? Icons.circle : Icons.circle_outlined,
            size: 8,
            color: connected ? AppColors.lilyGreenLight : AppColors.padLabelSoft,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                color: AppColors.pillText,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$words',
            style: const TextStyle(
              color: AppColors.padLabelSoft,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// A tappable pond glyph in a round pill hit target, used for both the
/// dictionary and (async) forfeit affordances.
class _HudIconButton extends StatelessWidget {
  const _HudIconButton({
    required this.glyph,
    required this.semanticLabel,
    required this.onTap,
  });

  final PondGlyph glyph;
  final String semanticLabel;
  final VoidCallback onTap;

  static const double _tapSize = 40;
  static const double _glyphSize = 20;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: SizedBox(
        width: _tapSize,
        height: _tapSize,
        child: Material(
          color: AppColors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Center(child: PondIcon(glyph, size: _glyphSize)),
          ),
        ),
      ),
    );
  }
}
