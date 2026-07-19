import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/audio/audio_providers.dart';
import '../../../../core/audio/sfx_keys.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../core/design/tokens/typography.dart';
import '../../../../shared/widgets/pond_background.dart';
import '../../../../shared/widgets/pond_page_header.dart';
import '../../../../shared/widgets/pond_pill_button.dart';
import '../../../../shared/widgets/pond_stage.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../game/presentation/widgets/streak_confetti.dart';
import '../../application/match_providers.dart';
import '../../domain/match_result.dart';
import '../widgets/match_load_error.dart';

class MatchResultPage extends ConsumerWidget {
  const MatchResultPage({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUid = ref.watch(currentUserProvider)?.uid;
    final matchAsync = ref.watch(matchStreamProvider(matchId));
    final match = matchAsync.value;

    final result = (match == null || myUid == null)
        ? null
        : MatchResult.fromFinishedMatch(match, myUid);

    // A listener that errored has no value, so it must not fall through to
    // the spinner; nor does a settled-but-null value (e.g. the match doc was
    // deleted). Either way there is nothing to show the result for.
    final failed = matchAsync.hasError || (matchAsync.hasValue && match == null);

    Widget body;
    if (result != null) {
      body = _ResultBody(result: result);
    } else if (failed) {
      body = MatchLoadError(
        onRetry: () => ref.invalidate(matchStreamProvider(matchId)),
      );
    } else {
      body = const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: AppColors.transparent,
      body: PondBackground(
        child: PondStage(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PondPageHeader(title: 'Result'),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultBody extends ConsumerStatefulWidget {
  const _ResultBody({required this.result});
  final MatchResult result;

  @override
  ConsumerState<_ResultBody> createState() => _ResultBodyState();
}

class _ResultBodyState extends ConsumerState<_ResultBody> {
  // Reusing StreakConfetti's own trigger (a rising `combo` value) fires its
  // burst once the result screen settles, rather than duplicating its
  // reduced-motion-aware particle logic here. 0 means "no burst yet".
  int _confettiCombo = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _celebrate());
  }

  void _celebrate() {
    if (!mounted) return;
    final result = widget.result;
    if (result.isWin) {
      setState(() => _confettiCombo = 2);
      _playSfxQuiet(SfxKeys.matchWon);
    } else if (result.isLoss) {
      _playSfxQuiet(SfxKeys.matchLost);
    }
  }

  void _playSfxQuiet(String key) {
    // Best-effort: mute-aware AudioService already no-ops when muted; a
    // failed play must never surface as an error on the result screen.
    unawaited(ref.read(audioServiceProvider).playSfx(key).catchError((_) {}));
  }

  String get _headline {
    final result = widget.result;
    if (result.isDraw) return 'Draw';
    return result.isWin ? 'You win' : 'You lose';
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    return Stack(
      children: [
        if (result.isWin)
          Positioned.fill(
            child: IgnorePointer(
              child: StreakConfetti(combo: _confettiCombo),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(),
              Text(
                _headline,
                style: AppTypography.matchResultHeadline.copyWith(
                  color: result.isWin
                      ? AppColors.lilyGreenLight
                      : AppColors.wordmark,
                ),
              ),
              if (result.winReason != null) ...[
                const SizedBox(height: AppSpacing.xs),
                _WinReasonLine(reason: result.winReason!),
              ],
              const SizedBox(height: AppSpacing.xl),
              _ScoreLine(
                label: 'You',
                score: result.myScore,
                wordsFound: result.myWordsFound,
              ),
              const SizedBox(height: AppSpacing.sm),
              _ScoreLine(
                label: result.opponentName,
                score: result.opponentScore,
                wordsFound: result.opponentWordsFound,
              ),
              const Spacer(),
              PondPillButton(
                // Not a real rematch: the client has no way to re-challenge
                // this exact opponent (MatchResult carries no opponent uid),
                // so this honestly opens a new match instead of implying it
                // replays the same pairing.
                label: 'Play again',
                onPressed: () =>
                    context.pushReplacement('/multiplayer?mode=create'),
              ),
              const SizedBox(height: AppSpacing.sm),
              PondPillButton(
                label: 'Home',
                variant: PondPillVariant.quiet,
                onPressed: () => context.go('/'),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ],
    );
  }
}

/// The concise line under the headline explaining which tier of the server's
/// winner algorithm decided the match (issue: a tied-looking scoreboard with
/// a decisive winner otherwise reads as unexplained).
String _winReasonLabel(MatchWinReason reason) => switch (reason) {
  MatchWinReason.wordsFound => 'Won by words found',
  MatchWinReason.speed => 'Won by speed',
  MatchWinReason.points => 'Won by points',
};

class _WinReasonLine extends StatelessWidget {
  const _WinReasonLine({required this.reason});
  final MatchWinReason reason;

  @override
  Widget build(BuildContext context) => Text(
    _winReasonLabel(reason),
    style: AppTypography.bannerSub.copyWith(color: AppColors.padLabelSoft),
  );
}

class _ScoreLine extends StatelessWidget {
  const _ScoreLine({
    required this.label,
    required this.score,
    required this.wordsFound,
  });
  final String label;
  final int score;
  final int wordsFound;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Flexible(
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: AppTypography.matchScoreLabel.copyWith(
            color: AppColors.padLabel,
          ),
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      Text.rich(
        TextSpan(
          style: AppTypography.matchScoreValue.copyWith(
            color: AppColors.padLabel,
          ),
          children: [
            TextSpan(text: '$score'),
            TextSpan(
              text: '  ·  $wordsFound ${wordsFound == 1 ? 'word' : 'words'}',
              style: AppTypography.bannerSub.copyWith(
                color: AppColors.padLabelSoft,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
