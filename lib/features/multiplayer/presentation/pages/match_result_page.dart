import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../core/design/tokens/typography.dart';
import '../../../../shared/widgets/pond_background.dart';
import '../../../../shared/widgets/pond_page_header.dart';
import '../../../../shared/widgets/pond_pill_button.dart';
import '../../../../shared/widgets/pond_stage.dart';
import '../../../auth/application/auth_providers.dart';
import '../../application/match_providers.dart';
import '../../domain/match_result.dart';

class MatchResultPage extends ConsumerWidget {
  const MatchResultPage({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUid = ref.watch(currentUserProvider)?.uid;
    final match = ref.watch(matchStreamProvider(matchId)).value;

    final result = (match == null || myUid == null)
        ? null
        : MatchResult.fromFinishedMatch(match, myUid);

    return Scaffold(
      backgroundColor: AppColors.transparent,
      body: PondBackground(
        child: PondStage(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PondPageHeader(title: 'Result'),
              Expanded(
                child: result == null
                    ? const Center(child: CircularProgressIndicator())
                    : _ResultBody(result: result),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultBody extends StatelessWidget {
  const _ResultBody({required this.result});
  final MatchResult result;

  String get _headline {
    if (result.isDraw) return 'Draw';
    return result.isWin ? 'You win' : 'You lose';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const Spacer(),
          Text(
            _headline,
            style: TextStyle(
              color: result.isWin
                  ? AppColors.lilyGreenLight
                  : AppColors.wordmark,
              fontSize: 40,
              fontWeight: FontWeight.w900,
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
            label: 'Rematch',
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
      Text(
        label,
        style: const TextStyle(
          color: AppColors.padLabel,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      Text.rich(
        TextSpan(
          style: const TextStyle(
            color: AppColors.padLabel,
            fontSize: 22,
            fontWeight: FontWeight.w900,
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
