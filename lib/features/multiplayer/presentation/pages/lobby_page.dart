import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/pond_background.dart';
import '../../../../shared/widgets/pond_page_header.dart';
import '../../../../shared/widgets/pond_pill_button.dart';
import '../../../../shared/widgets/pond_stage.dart';
import '../../../auth/application/auth_providers.dart';
import '../../application/match_providers.dart';
import '../../domain/match.dart';
import '../../domain/match_player.dart';
import '../widgets/match_load_error.dart';

class LobbyPage extends ConsumerWidget {
  const LobbyPage({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUid = ref.watch(currentUserProvider)?.uid;
    // Navigate out of the lobby as the status advances.
    ref.listen(matchStreamProvider(matchId), (_, next) {
      final m = next.value;
      if (m == null) return;
      if (m.status == MatchStatus.active || m.status == MatchStatus.countdown) {
        context.pushReplacement('/multiplayer/match/$matchId');
      } else if (m.status == MatchStatus.cancelled) {
        context.go('/');
      }
    });

    final matchAsync = ref.watch(matchStreamProvider(matchId));
    final match = matchAsync.value;

    return Scaffold(
      backgroundColor: AppColors.transparent,
      body: PondBackground(
        child: PondStage(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PondPageHeader(
                title: 'Lobby',
                onBack: () => _leaveToHome(context, ref),
              ),
              Expanded(
                // An errored listener has no value, so it must not fall through
                // to the spinner: that is the "refresh hangs forever" bug.
                child: matchAsync.hasError && match == null
                    ? MatchLoadError(
                        onRetry: () =>
                            ref.invalidate(matchStreamProvider(matchId)),
                      )
                    : match == null
                    ? const Center(child: CircularProgressIndicator())
                    : _LobbyBody(match: match, myUid: myUid, matchId: matchId),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Back = leave the lobby and return home. Pop FIRST so the match-stream
  /// listener on this page is disposed before the leave call flips the match
  /// to cancelled (otherwise the cancelled branch would immediately
  /// pushReplacement us back into matchmaking).
  void _leaveToHome(BuildContext context, WidgetRef ref) {
    final service = ref.read(matchServiceProvider);
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
    service.leave(matchId).ignore();
  }
}

class _LobbyBody extends ConsumerWidget {
  const _LobbyBody({
    required this.match,
    required this.myUid,
    required this.matchId,
  });
  final Match match;
  final String? myUid;
  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = myUid == null ? null : match.playerFor(myUid!);
    final isCreator = myUid != null && match.isCreator(myUid!);
    final service = ref.read(matchServiceProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),
          const Text(
            'Match lobby',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.wordmark,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _CodeCard(code: match.code),
          const SizedBox(height: AppSpacing.lg),
          for (final uid in match.playerOrder)
            _PlayerRow(player: match.playerFor(uid), isMe: uid == myUid),
          if (!match.hasOpponent)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.md),
              child: Text(
                'Waiting for an opponent to join...',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.padLabelSoft),
              ),
            ),
          const Spacer(),
          PondPillButton(
            label: (me?.ready ?? false) ? 'Not ready' : 'Ready',
            // PondPillButton.onPressed is non-nullable; `enabled` gates taps.
            enabled: me != null,
            onPressed: () {
              final self = me;
              if (self != null) service.ready(matchId, ready: !self.ready);
            },
          ),
          if (isCreator) ...[
            const SizedBox(height: AppSpacing.sm),
            PondPillButton(
              label: 'Start now',
              variant: PondPillVariant.quiet,
              enabled: match.hasOpponent,
              onPressed: () => service.start(matchId),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          PondPillButton(
            label: 'Leave',
            variant: PondPillVariant.quiet,
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
              service.leave(matchId).ignore();
            },
          ),
        ],
      ),
    );
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.code});
  final String code;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Clipboard.setData(ClipboardData(text: code)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.pillFill,
          borderRadius: AppRadii.card,
          border: Border.all(color: AppColors.settingsBorder),
        ),
        child: Column(
          children: [
            const Text(
              'Share this code',
              style: TextStyle(color: AppColors.padLabelSoft, fontSize: 12),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              code,
              style: const TextStyle(
                color: AppColors.pillText,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.player, required this.isMe});
  final MatchPlayer? player;
  final bool isMe;
  @override
  Widget build(BuildContext context) {
    final p = player;
    final name = p == null
        ? 'Empty seat'
        : '${p.displayName}${isMe ? ' (you)' : ''}';
    final ready = p?.ready ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            ready ? Icons.check_circle_rounded : Icons.person_outline_rounded,
            color: ready ? AppColors.lilyGreenLight : AppColors.padLabelSoft,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            name,
            style: const TextStyle(color: AppColors.padLabel, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
