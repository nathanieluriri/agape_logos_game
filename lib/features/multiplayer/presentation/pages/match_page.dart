import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/pond_background.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../game/presentation/widgets/formed_word_pill.dart';
import '../../../game/presentation/widgets/letter_wheel.dart';
import '../../../game/presentation/widgets/wheel_action_button.dart';
import '../../../game/presentation/widgets/word_board.dart';
import '../../../puzzles/domain/puzzle.dart';
import '../../application/match_controller.dart';
import '../../application/match_providers.dart';
import '../../domain/match.dart';
import '../../domain/match_event.dart';
import '../../domain/match_rack.dart';
import '../widgets/fog_overlay.dart';
import '../widgets/frozen_letter_overlay.dart';
import '../widgets/match_timer.dart';
import '../widgets/opponent_hud.dart';
import '../widgets/powerup_bar.dart';

class MatchPage extends ConsumerStatefulWidget {
  const MatchPage({super.key, required this.matchId});

  final String matchId;

  @override
  ConsumerState<MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends ConsumerState<MatchPage> {
  // PLAN: mirrors AppSizing.wheelDiameter (260). A const Size cannot reference
  // the token directly; keep the two equal if the token ever changes.
  static const _wheelSize = Size(260, 260);
  Timer? _ticker;
  int _now = DateTime.now().millisecondsSinceEpoch;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(matchPlayControllerProvider.notifier).reset();
    });
    // One clock for the timer, freeze expiry, and fog expiry.
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => _now = DateTime.now().millisecondsSinceEpoch);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _submit(String word) async {
    try {
      await ref.read(matchServiceProvider).submit(widget.matchId, word);
    } catch (_) {
      // The server is authoritative; a failed submit simply does not score.
      // The optimistic pending word is reconciled away on the next rack tick.
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchId = widget.matchId;
    final myUid = ref.watch(currentUserProvider)?.uid;

    // Keep the local play state aligned with the private rack.
    ref.listen(myRackStreamProvider(matchId), (_, next) {
      final rack = next.value;
      if (rack != null) {
        ref.read(matchPlayControllerProvider.notifier).syncRack(rack);
      }
    });
    // Apply incoming one-shot effects (scramble reshuffles once; word-steal
    // drops the local optimistic word). Deduped by event id in the controller.
    ref.listen(matchEventsStreamProvider(matchId), (_, next) {
      final ctrl = ref.read(matchPlayControllerProvider.notifier);
      for (final e in next.value ?? const <MatchEvent>[]) {
        if (e.kind == MatchEventKind.scramble) {
          ctrl.applyScramble(e.id);
        } else if (e.kind == MatchEventKind.wordSteal) {
          final w = e.stolenWord;
          if (w != null) ctrl.applyWordSteal(e.id, w);
        }
      }
    });
    // Navigate to the result screen once the match finishes.
    ref.listen(matchStreamProvider(matchId), (_, next) {
      final m = next.value;
      if (m != null && m.status == MatchStatus.finished && !_navigated) {
        _navigated = true;
        context.pushReplacement('/multiplayer/result/$matchId');
      }
    });

    final match = ref.watch(matchStreamProvider(matchId)).value;
    final rack = ref.watch(myRackStreamProvider(matchId)).value;
    final effects = ref.watch(activeEffectsProvider(matchId));
    final playState = ref.watch(matchPlayControllerProvider);

    return Scaffold(
      body: PondBackground(
        child: SafeArea(
          child: _content(match, rack, effects, playState, myUid),
        ),
      ),
    );
  }

  Widget _content(
    Match? match,
    MatchRack? rack,
    ActiveEffects effects,
    MatchPlayState playState,
    String? myUid,
  ) {
    if (match == null || rack == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (match.status == MatchStatus.lobby ||
        match.status == MatchStatus.countdown) {
      return const Center(
        child: Text(
          'Get ready...',
          style: TextStyle(
            color: AppColors.wordmark,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }
    if (!rack.decrypted) {
      return const Center(
        child: Text('Preparing your rack...',
            style: TextStyle(color: AppColors.padLabelSoft)),
      );
    }

    final controller = ref.read(matchPlayControllerProvider.notifier);
    final order = playState.rackOrder.length == rack.letters.length
        ? playState.rackOrder
        : List<int>.generate(rack.letters.length, (i) => i);
    final wheelLetters = [for (final i in order) rack.letters[i]];

    // Which SLOTS are frozen right now (map rack letter index -> slot via order).
    final frozenSlots = <int>{};
    for (var slot = 0; slot < order.length; slot++) {
      final exp = effects.frozenLetters[order[slot]];
      if (exp != null && exp > _now) frozenSlots.add(slot);
    }
    final fogActive = effects.fogUntil != null && effects.fogUntil! > _now;

    final myScore = myUid == null ? 0 : (match.playerFor(myUid)?.score ?? 0);
    final found = <String>{
      ...rack.foundWords.map((w) => w.toUpperCase()),
      ...playState.pendingFound,
    };
    final targets = [
      for (final a in rack.targets)
        PuzzleAnswer(word: a.word, length: a.length, definition: null),
    ];
    final formed =
        [for (final s in playState.selection) wheelLetters[s]].join().toUpperCase();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MyScore(score: myScore),
              MatchTimer(endsAt: match.endsAt, nowMillis: _now),
              OpponentHud(opponent: myUid == null ? null : match.opponentOf(myUid)),
            ],
          ),
        ),
        Expanded(
          child: FogOverlay(
            active: fogActive,
            child: WordBoard(
              targets: targets,
              found: found,
              revealed: const {},
              center: true,
            ),
          ),
        ),
        FormedWordPill(word: formed),
        const SizedBox(height: AppSpacing.sm),
        PowerupBar(matchId: match.matchId),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                WheelActionButton(
                  icon: Icons.shuffle,
                  semanticLabel: 'Shuffle',
                  onTap: controller.shuffle,
                ),
                const SizedBox(width: AppSpacing.lg),
                SizedBox(
                  width: _wheelSize.width,
                  height: _wheelSize.height,
                  child: Stack(
                    children: [
                      LetterWheel(
                        letters: wheelLetters,
                        selected: playState.selection,
                        ids: order,
                        onTouch: (slot) =>
                            controller.touchLetter(slot, frozen: frozenSlots),
                        onEnd: () {
                          final word = controller.endSelection(rack, found);
                          if (word != null) _submit(word);
                        },
                      ),
                      Positioned.fill(
                        child: FrozenLetterOverlay(
                          frozenSlots: frozenSlots,
                          letterCount: wheelLetters.length,
                          size: _wheelSize,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                WheelActionButton(
                  icon: Icons.flag_outlined,
                  semanticLabel: 'Leave match',
                  onTap: () async {
                    await ref.read(matchServiceProvider).leave(match.matchId);
                    // `context` here is State.context, so guard on the State's
                    // own `mounted`, not `context.mounted`.
                    if (!mounted) return;
                    context.go('/');
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MyScore extends StatelessWidget {
  const _MyScore({required this.score});
  final int score;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('You',
              style: TextStyle(color: AppColors.padLabelSoft, fontSize: 12)),
          Text(
            '$score',
            style: const TextStyle(
              color: AppColors.padLabel,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
}
