import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/pond_background.dart';
import '../../../../shared/widgets/pond_page_header.dart';
import '../../../../shared/widgets/pond_pill_button.dart';
import '../../../../shared/widgets/pond_stage.dart';
import '../../application/match_providers.dart';
import '../../application/resume_providers.dart';
import '../../domain/active_match.dart';
import '../../domain/challenge_invite.dart';
import '../widgets/match_timer.dart';

/// Resume Games: incoming challenges to accept/decline, plus the player's
/// in-progress matches, so an async 6-hour game can be played across sittings.
class ResumeGamesPage extends ConsumerWidget {
  const ResumeGamesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenges = ref.watch(incomingChallengesProvider);
    final games = ref.watch(activeMatchesProvider);
    return Scaffold(
      backgroundColor: AppColors.transparent,
      body: PondBackground(
        child: PondStage.fill(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PondPageHeader(title: 'Resume games'),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(activeMatchesProvider),
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      ..._challengeSection(context, ref, challenges),
                      ..._gamesSection(context, ref, games),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _challengeSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<ChallengeInvite>> challenges,
  ) {
    final list = challenges.value ?? const <ChallengeInvite>[];
    if (list.isEmpty) return const [];
    final busy = ref.watch(challengeActionsControllerProvider);
    final actions = ref.read(challengeActionsControllerProvider.notifier);
    return [
      const _SectionLabel('Incoming challenges'),
      for (final c in list)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _ChallengeTile(
            invite: c,
            busy: busy.contains(c.matchId),
            onAccept: () async {
              final ok = await actions.respond(c.matchId, accept: true);
              if (ok && context.mounted) {
                context.push(
                  c.isAsync
                      ? '/multiplayer/match/${c.matchId}'
                      : '/multiplayer/lobby/${c.matchId}',
                );
              }
            },
            onDecline: () => actions.respond(c.matchId, accept: false),
          ),
        ),
      const SizedBox(height: AppSpacing.md),
    ];
  }

  List<Widget> _gamesSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<ActiveMatch>> games,
  ) {
    return [
      const _SectionLabel('Your games'),
      ...games.when(
        loading: () => const [_Hint('Loading your games...')],
        error: (_, __) => const [_Hint('Could not load your games.')],
        data: (list) => list.isEmpty
            ? const [_Hint('No games in progress.')]
            : [
                for (final m in list)
                  Padding(
                    key: ValueKey<String>(m.matchId),
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _GameTile(
                      match: m,
                      onTap: () => context.push(
                        m.isLobby
                            ? '/multiplayer/lobby/${m.matchId}'
                            : '/multiplayer/match/${m.matchId}',
                      ),
                      // The match may have already settled server-side by the
                      // time this tile's own countdown hits zero (see #32);
                      // refreshing here drops it from the list without a
                      // manual pull-to-refresh.
                      onExpired: () => ref.invalidate(activeMatchesProvider),
                    ),
                  ),
              ],
      ),
    ];
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.padLabel,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: AppColors.padLabelSoft, fontSize: 14),
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.pillFill,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.settingsBorder),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: card,
    );
  }
}

class _ChallengeTile extends StatelessWidget {
  const _ChallengeTile({
    required this.invite,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
  });

  final ChallengeInvite invite;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final who = invite.displayName.isNotEmpty
        ? invite.displayName
        : (invite.handle.isNotEmpty ? '@${invite.handle}' : 'A friend');
    final modeLabel = invite.isAsync ? '6-hour game' : 'Play now';
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$who challenged you',
            style: const TextStyle(
              color: AppColors.padLabel,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            modeLabel,
            style: const TextStyle(
              color: AppColors.padLabelSoft,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              PondPillButton(
                label: 'Accept',
                enabled: !busy,
                onPressed: onAccept,
              ),
              const SizedBox(width: AppSpacing.sm),
              PondPillButton(
                label: 'Decline',
                variant: PondPillVariant.quiet,
                enabled: !busy,
                onPressed: onDecline,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A single "Your games" row: opponent, live score, and (async matches only)
/// a live countdown that reuses the shared [MatchTimer] pill (its m:ss / h:mm
/// formatting and sub-30s urgency styling) instead of a duplicated formatter.
/// Owns its own ticker so the countdown moves without the tile ever being
/// rebuilt from outside, and calls [onExpired] once when the countdown hits
/// zero so the caller can refresh the settled match off the list.
class _GameTile extends ConsumerStatefulWidget {
  const _GameTile({
    required this.match,
    required this.onTap,
    required this.onExpired,
  });

  final ActiveMatch match;
  final VoidCallback onTap;
  final VoidCallback onExpired;

  @override
  ConsumerState<_GameTile> createState() => _GameTileState();
}

class _GameTileState extends ConsumerState<_GameTile> {
  static const _tick = Duration(seconds: 1);

  Timer? _timer;
  bool _expired = false;

  /// Re-read from the server-corrected clock (see `match_page.dart`'s use of
  /// `serverClockProvider`) rather than stepped by a fixed tick amount, so the
  /// countdown stays correct under jank/frame delay and under device clock
  /// skew (a fixed step cannot correct for either).
  int _now = 0;

  bool get _showsCountdown => widget.match.isAsync && widget.match.endsAt > 0;

  @override
  void initState() {
    super.initState();
    _now = ref.read(serverClockProvider).now().millisecondsSinceEpoch;
    if (_showsCountdown) _timer = Timer.periodic(_tick, (_) => _onTick());
  }

  void _onTick() {
    if (!mounted) return;
    final now = ref.read(serverClockProvider).now().millisecondsSinceEpoch;
    final justExpired = !_expired && now >= widget.match.endsAt;
    setState(() => _now = now);
    if (justExpired) {
      _expired = true;
      _timer?.cancel();
      widget.onExpired();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    return _Card(
      onTap: widget.onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.opponentName,
                  style: const TextStyle(
                    color: AppColors.padLabel,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${match.myScore} - ${match.opponentScore}',
                  style: const TextStyle(
                    color: AppColors.padLabelSoft,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (_showsCountdown)
            MatchTimer(endsAt: match.endsAt, nowMillis: _now),
        ],
      ),
    );
  }
}
