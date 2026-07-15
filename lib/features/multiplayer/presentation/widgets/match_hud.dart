import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/design/tokens/colors.dart';
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
  });

  final int myScore;
  final int myWords;
  final String opponentName;
  final int opponentWords;
  final bool opponentConnected;
  final DateTime endsAt;
  final VoidCallback onDictionary;

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
          _MyScorePip(score: myScore, words: myWords),
          const SizedBox(width: AppSpacing.sm),
          _TickingTimer(endsAt: endsAt),
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
  const _TickingTimer({required this.endsAt});

  final DateTime endsAt;

  @override
  State<_TickingTimer> createState() => _TickingTimerState();
}

class _TickingTimerState extends State<_TickingTimer> {
  Timer? _timer;
  int _now = DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now().millisecondsSinceEpoch);
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

/// "You" + my score, sized to stay legible without eating the row.
class _MyScorePip extends StatelessWidget {
  const _MyScorePip({required this.score, required this.words});

  final int score;
  final int words;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'You',
          style: TextStyle(color: AppColors.padLabelSoft, fontSize: 12),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '$score',
          style: const TextStyle(
            color: AppColors.padLabel,
            fontSize: 24,
            fontWeight: FontWeight.w800,
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
