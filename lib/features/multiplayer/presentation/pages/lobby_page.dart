import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/motion/curves.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/durations.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../core/design/tokens/typography.dart';
import '../../../../shared/widgets/pond_background.dart';
import '../../../../shared/widgets/pond_loader.dart';
import '../../../../shared/widgets/pond_page_header.dart';
import '../../../../shared/widgets/pond_pill_button.dart';
import '../../../../shared/widgets/pond_stage.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../social/presentation/widgets/social_avatar_dot.dart';
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

class _LobbyBody extends ConsumerStatefulWidget {
  const _LobbyBody({
    required this.match,
    required this.myUid,
    required this.matchId,
  });
  final Match match;
  final String? myUid;
  final String matchId;

  @override
  ConsumerState<_LobbyBody> createState() => _LobbyBodyState();
}

class _LobbyBodyState extends ConsumerState<_LobbyBody> {
  Timer? _stillSearchingTimer;
  Timer? _joinConfirmTimer;
  bool _stillSearching = false;
  String? _justJoinedName;

  @override
  void initState() {
    super.initState();
    _armStillSearchingTimer();
  }

  void _armStillSearchingTimer() {
    _stillSearchingTimer?.cancel();
    _stillSearchingTimer = null;
    if (widget.match.hasOpponent) return;
    _stillSearchingTimer = Timer(AppDurations.lobbyStillSearchingAfter, () {
      if (mounted) setState(() => _stillSearching = true);
    });
  }

  @override
  void didUpdateWidget(covariant _LobbyBody old) {
    super.didUpdateWidget(old);
    if (!old.match.hasOpponent && widget.match.hasOpponent) {
      final opponentUid = widget.match.playerOrder.firstWhere(
        (uid) => uid != widget.myUid,
        orElse: () => '',
      );
      final opponent = widget.match.playerFor(opponentUid);
      _stillSearchingTimer?.cancel();
      _stillSearchingTimer = null;
      _joinConfirmTimer?.cancel();
      setState(() {
        _stillSearching = false;
        _justJoinedName = opponent?.displayName;
      });
      _joinConfirmTimer = Timer(AppDurations.lobbyJoinConfirmHold, () {
        if (mounted) setState(() => _justJoinedName = null);
      });
    } else if (old.match.hasOpponent && !widget.match.hasOpponent) {
      _armStillSearchingTimer();
    }
  }

  @override
  void dispose() {
    _stillSearchingTimer?.cancel();
    _joinConfirmTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final myUid = widget.myUid;
    final me = myUid == null ? null : match.playerFor(myUid);
    final isCreator = myUid != null && match.isCreator(myUid);
    final service = ref.read(matchServiceProvider);
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Match lobby',
            textAlign: TextAlign.center,
            style: AppTypography.matchSectionTitle.copyWith(
              color: AppColors.wordmark,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _CodeCard(code: match.code),
          const SizedBox(height: AppSpacing.lg),
          for (final uid in match.playerOrder)
            _PlayerRow(
              key: ValueKey(uid),
              player: match.playerFor(uid),
              isMe: uid == myUid,
              reduceMotion: reduceMotion,
            ),
          AnimatedSize(
            duration: AppDurations.fast,
            curve: AppCurves.enter,
            child: _justJoinedName != null
                ? Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Text(
                      '${_justJoinedName!} joined!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.lilyGreenLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          if (!match.hasOpponent) ...[
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.lg),
              child: PondLoader(label: 'Waiting for an opponent to join...'),
            ),
            AnimatedSize(
              duration: AppDurations.fast,
              curve: AppCurves.enter,
              child: _stillSearching
                  ? const Padding(
                      padding: EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        'Still searching... share the code above to speed it up.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.padLabelSoft),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
          const Spacer(),
          PondPillButton(
            label: (me?.ready ?? false) ? 'Not ready' : 'Ready',
            // PondPillButton.onPressed is non-nullable; `enabled` gates taps.
            enabled: me != null,
            onPressed: () {
              final self = me;
              if (self != null) {
                service.ready(widget.matchId, ready: !self.ready);
              }
            },
          ),
          if (isCreator) ...[
            const SizedBox(height: AppSpacing.sm),
            PondPillButton(
              label: 'Start now',
              variant: PondPillVariant.quiet,
              enabled: match.hasOpponent,
              onPressed: () => service.start(widget.matchId),
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
              service.leave(widget.matchId).ignore();
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
              style: AppTypography.matchCode.copyWith(
                color: AppColors.pillText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One lobby seat. Fades and rises in on its first appearance (notably the
/// opponent's row, the moment they join) unless reduced motion is requested,
/// in which case it snaps straight to its settled state.
class _PlayerRow extends StatefulWidget {
  const _PlayerRow({
    super.key,
    required this.player,
    required this.isMe,
    required this.reduceMotion,
  });
  final MatchPlayer? player;
  final bool isMe;
  final bool reduceMotion;

  @override
  State<_PlayerRow> createState() => _PlayerRowState();
}

class _PlayerRowState extends State<_PlayerRow>
    with SingleTickerProviderStateMixin {
  static const double _riseDistance = 12;

  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: AppDurations.lobbyRowEnter,
  );

  @override
  void initState() {
    super.initState();
    if (widget.reduceMotion) {
      _enter.value = 1;
    } else {
      _enter.forward();
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.player;
    final name = p == null
        ? 'Empty seat'
        : '${p.displayName}${widget.isMe ? ' (you)' : ''}';
    final ready = p?.ready ?? false;
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          SocialAvatarDot(name: p?.displayName ?? '?', size: 32),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(color: AppColors.padLabel, fontSize: 16),
            ),
          ),
          if (ready)
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.lilyGreenLight,
            ),
        ],
      ),
    );
    if (widget.reduceMotion) return row;
    return AnimatedBuilder(
      animation: _enter,
      child: row,
      builder: (context, child) {
        final t = AppCurves.enter.transform(_enter.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, _riseDistance * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}
