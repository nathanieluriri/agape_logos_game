import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/audio/audio_providers.dart';
import '../../../../core/audio/sfx_keys.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/haptics/haptics.dart';
import '../../../../core/design/tokens/sizing.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/animated_app_icon.dart';
import '../../../../shared/widgets/pond_background.dart';
import '../../../../shared/widgets/pond_dialog.dart';
import '../../../../shared/widgets/pond_pill_button.dart';
import '../../../../shared/widgets/pond_snack.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../game/presentation/widgets/dictionary_sheet.dart';
import '../../../game/presentation/widgets/formed_word_pill.dart';
import '../../../game/presentation/widgets/letter_wheel.dart';
import '../../../game/presentation/widgets/wheel_action_button.dart';
import '../../../game/presentation/widgets/word_board.dart';
import '../../../puzzles/domain/puzzle.dart';
import '../../../store/application/store_providers.dart';
import '../../../store/domain/store_item.dart';
import '../../application/match_controller.dart';
import '../../application/match_providers.dart';
import '../../domain/match.dart';
import '../../domain/match_event.dart';
import '../../domain/match_rack.dart';
import '../../domain/match_settings.dart';
import '../../domain/powerup_kind.dart';
import '../widgets/active_effect_chips.dart';
import '../widgets/fog_overlay.dart';
import '../widgets/frozen_letter_overlay.dart';
import '../widgets/match_hud.dart';
import '../widgets/match_load_error.dart';
import '../widgets/powerup_cast_flyout.dart';
import '../widgets/powerup_incoming_banner.dart';
import '../widgets/powerup_info_sheet.dart';
import '../widgets/powerup_side_buttons.dart';
import '../widgets/powerup_tutorial_overlay.dart';
import '../widgets/powerup_wheel.dart';

/// How often anything on the match page consults the wall clock. Not a motion
/// token: this is a polling interval, not an animation.
const Duration kMatchTick = Duration(milliseconds: 500);

/// Rebuilds only its own subtree on the match tick, handing the builder the
/// current wall clock. [child] is passed through untouched, so a subtree that
/// does not depend on the clock (the word board under the fog) is not rebuilt.
class _Ticking extends StatefulWidget {
  const _Ticking({required this.builder, required this.now, this.child});

  final Widget Function(BuildContext context, int nowMillis, Widget? child)
  builder;

  /// Server-adjusted clock reader (`ref.read(serverClockProvider).now`), so a
  /// device clock that is skewed behind the server still ends a timed effect
  /// (fog, freeze) on time.
  final DateTime Function() now;
  final Widget? child;

  @override
  State<_Ticking> createState() => _TickingState();
}

class _TickingState extends State<_Ticking> {
  Timer? _timer;
  late int _now = widget.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(kMatchTick, (_) {
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
  Widget build(BuildContext context) =>
      widget.builder(context, _now, widget.child);
}

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
  // Memo keys: the derived board/wheel data is rebuilt only when the rack or the
  // play state that feeds it actually changes, never on a clock tick.
  MatchRack? _targetsKey;
  List<PuzzleAnswer>? _targets;
  MatchRack? _foundRackKey;
  Set<String>? _foundPendingKey;
  Set<String>? _found;
  MatchRack? _wheelRackKey;
  List<int>? _wheelOrderKey;
  List<int>? _order;
  List<String>? _wheelLetters;
  // One settle poke per clock boundary (start, end). Re-armed if the call fails,
  // so a dropped request retries on the next tick instead of stranding the match.
  bool _pokedStart = false;
  bool _pokedEnd = false;

  // Which powerup wheel (if any) is open. Task 8's tutorial spotlights these
  // via the exposed GlobalKeys: the offense button, the defense button, and
  // the first slot of whichever wheel is open.
  PowerupCategory? _openPowerupCategory;
  final GlobalKey powerupOffenseButtonKey = GlobalKey();
  final GlobalKey powerupDefenseButtonKey = GlobalKey();
  final GlobalKey powerupWheelSlotKey = GlobalKey();

  // Task 6: cast/incoming/blocked animations. Every event id (fired-at-me
  // event or my own blocked/warded outcome) animates at most once, even
  // across duplicate stream emissions of the same doc.
  final Set<String> _seenEventIds = <String>{};
  final List<IncomingBannerData> _bannerQueue = <IncomingBannerData>[];
  IncomingBannerData? _activeBanner;

  // The events stream replays every historical event targeting me on each
  // fresh listen (a doc query, not a since-cursor), so re-entering a match
  // (async resume) would otherwise queue a banner + SFX for every event ever
  // fired at me. Seed `_seenEventIds` from the FIRST emission without
  // animating anything; only events that arrive AFTER that snapshot animate.
  bool _eventsSeeded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(matchPlayControllerProvider.notifier).reset();
    });
    // The page clock only drives the settle pokes and the phase gate (lobby /
    // countdown / play / time's up). The leaf widgets that show a live time (the
    // match timer, the fog and freeze expiries) carry their own tick, so a
    // second of clock never rebuilds the board, the wheel, or the powerup bar.
    _ticker = Timer.periodic(kMatchTick, (_) => _onTick());
  }

  void _onTick() {
    if (!mounted) return;
    final int now = DateTime.now().millisecondsSinceEpoch;
    final Match? match = ref.read(matchStreamProvider(widget.matchId)).value;
    if (match == null) {
      _now = now;
      return;
    }
    _settleAtBoundaries(match, now);
    final bool gateMoved = _gate(match, _now) != _gate(match, now);
    _now = now;
    if (gateMoved) setState(() {});
  }

  /// What the page shows at [now]: the phase, plus the countdown numeral while
  /// there is one. The page rebuilds only when this changes.
  (int, int) _gate(Match m, int now) {
    if (m.status == MatchStatus.lobby || m.countingDownAt(now)) {
      return (0, m.countdownSecondsAt(now));
    }
    if (!m.playableAt(now) && m.status != MatchStatus.finished) return (1, 0);
    return (2, 0);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// The server persists `countdown -> active` and `active -> finished` only
  /// while serving a request (`settleMatch`). Nothing else does. So if neither
  /// player writes, the doc never advances: the match never starts, and once the
  /// round is over it never finalizes, leaving both players stranded until the
  /// scheduled sweeper eventually cancels it. Poke the settling GET once as each
  /// boundary passes, and let the listener deliver the new doc.
  void _settleAtBoundaries(Match m, int now) {
    final bool startDue =
        m.status == MatchStatus.countdown &&
        m.startedAt > 0 &&
        now >= m.startedAt;
    final bool endDue =
        m.endsAt > 0 &&
        now >= m.endsAt &&
        m.status != MatchStatus.finished &&
        m.status != MatchStatus.cancelled;

    if (startDue && !_pokedStart) {
      _pokedStart = true;
      _poke(() => _pokedStart = false);
    }
    if (endDue && !_pokedEnd) {
      _pokedEnd = true;
      _poke(() => _pokedEnd = false);
    }
  }

  void _poke(VoidCallback rearm) {
    ref.read(matchServiceProvider).settle(widget.matchId).catchError((_) {
      // Offline or a transient failure: re-arm so the next tick tries again.
      if (mounted) rearm();
    });
  }

  /// A wheel slot was dragged out and released: fire [kind] at the match,
  /// close the wheel, and launch the cast flyout from the release point.
  /// Mirrors the old PowerupBar flow (optimistic inventory decrement) but
  /// spends UP FRONT (rather than on success) so the flyout and the decrement
  /// land together; a "warded"/402 outcome refunds the decrement once the
  /// server responds (contract: `MatchRemote.powerup` -> `PowerupFireResult`).
  Future<void> _firePowerup(String kind, Offset releaseGlobal) async {
    setState(() => _openPowerupCategory = null);
    final inventory =
        ref.read(inventoryControllerProvider).value ?? const <String, int>{};
    final itemId = powerupItemId(kind) ?? '';
    final owned = inventory[itemId] ?? 0;
    final decremented = itemId.isNotEmpty && owned > 0;
    if (decremented) {
      ref
          .read(inventoryControllerProvider.notifier)
          .applyServer({...inventory, itemId: owned - 1});
    }

    PowerupCastFlyout.show(context, kind, from: releaseGlobal);
    _playSfxQuiet(SfxKeys.powerupCast);
    Haptics.instance.mediumImpact();

    final result = await ref
        .read(matchServiceProvider)
        .powerup(widget.matchId, kind, eventId: const Uuid().v4());
    if (!mounted) return;

    if (!result.ok && decremented) {
      // Refund by incrementing whatever count is CURRENT at refund time, not
      // by restoring the pre-fire snapshot: two overlapping fires would
      // otherwise let the later refund clobber the newer state and lose or
      // duplicate inventory counts.
      final current =
          ref.read(inventoryControllerProvider).value ?? const <String, int>{};
      final refunded = (current[itemId] ?? 0) + 1;
      ref
          .read(inventoryControllerProvider.notifier)
          .applyServer({...current, itemId: refunded});
    }

    if (result.reason == 'warded') {
      _playSfxQuiet(SfxKeys.powerupBlocked);
      Haptics.instance.mistakeImpact();
      showPondSnack(context, 'Warded!');
      return;
    }
    if (!result.ok) {
      Haptics.instance.mistakeImpact();
      showPondSnack(context, 'Could not fire that powerup');
      return;
    }
    if (result.reason == 'blocked') {
      _playSfxQuiet(SfxKeys.powerupBlocked);
      Haptics.instance.mistakeImpact();
      showPondSnack(context, 'Blocked!');
    }
  }

  void _playSfxQuiet(String key) {
    // Best-effort: no audio asset ships at this key yet (see sfx_keys.dart),
    // so a failed play must never surface as an error in the match.
    unawaited(ref.read(audioServiceProvider).playSfx(key).catchError((_) {}));
  }

  /// Resolves a wire kind ('fog_bank', ...) to the display name the store
  /// catalog gives it, falling back to the item id (or the raw kind) while
  /// the catalog is still loading.
  String _powerupDisplayName(String wireKind) {
    final itemId = powerupItemId(wireKind);
    final catalog = ref.read(storeCatalogProvider).value ?? const <StoreItem>[];
    for (final item in catalog) {
      if (item.id == itemId) return item.name;
    }
    return itemId ?? wireKind;
  }

  /// Queues the incoming banner for a fired-at-me event, deduped by event id
  /// so a duplicate stream emission never animates twice.
  void _handleIncomingEvent(MatchEvent e) {
    if (!_seenEventIds.add(e.id)) return;
    final match = ref.read(matchStreamProvider(widget.matchId)).value;
    final blocked = e.kind == MatchEventKind.blocked;
    final wireKind = blocked
        ? (e.originalKind ?? '')
        : matchEventKindToWire(e.kind);
    if (wireKind.isEmpty) return; // unknown/warded: nothing to show
    final data = IncomingBannerData(
      casterName: match?.playerFor(e.byUid)?.displayName ?? 'Opponent',
      powerupName: _powerupDisplayName(wireKind),
      blocked: blocked,
    );
    _bannerQueue.add(data);
    _advanceBannerQueue();
  }

  void _advanceBannerQueue() {
    if (_activeBanner != null || _bannerQueue.isEmpty || !mounted) return;
    final next = _bannerQueue.removeAt(0);
    _playSfxQuiet(
      next.blocked ? SfxKeys.powerupBlocked : SfxKeys.powerupIncoming,
    );
    // A real hit lands hard; a blocked one gives the distinct error buzz.
    if (next.blocked) {
      Haptics.instance.mistakeImpact();
    } else {
      Haptics.instance.heavyImpact();
    }
    setState(() => _activeBanner = next);
  }

  void _onBannerDone() {
    if (!mounted) return;
    setState(() => _activeBanner = null);
    _advanceBannerQueue();
  }

  void _openPowerupInfo(List<StoreItem> catalog, String itemId) {
    StoreItem? item;
    for (final candidate in catalog) {
      if (candidate.id == itemId) {
        item = candidate;
        break;
      }
    }
    if (item == null) return;
    PowerupInfoSheet.show(context, ref, item);
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
      final events = next.value ?? const <MatchEvent>[];
      if (!_eventsSeeded) {
        // First emission of a fresh listen: these are historical events (some
        // possibly from a prior sitting), not new ones. Mark them seen so a
        // later duplicate emission never animates them, but do not animate or
        // apply them now.
        _eventsSeeded = true;
        _seenEventIds.addAll(events.map((e) => e.id));
        return;
      }
      final ctrl = ref.read(matchPlayControllerProvider.notifier);
      for (final e in events) {
        if (e.kind == MatchEventKind.scramble) {
          ctrl.applyScramble(e.id);
        } else if (e.kind == MatchEventKind.wordSteal) {
          final w = e.stolenWord;
          if (w != null) ctrl.applyWordSteal(e.id, w);
        }
        _handleIncomingEvent(e);
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

    final matchAsync = ref.watch(matchStreamProvider(matchId));
    final rackAsync = ref.watch(myRackStreamProvider(matchId));
    final match = matchAsync.value;
    final rack = rackAsync.value;
    // A listener that errored has no value; without this it would read as
    // "still loading" and spin forever.
    final failed =
        (matchAsync.hasError && match == null) ||
        (rackAsync.hasError && rack == null);
    if (match != null) _settleAtBoundaries(match, _now);
    final effects = ref.watch(activeEffectsProvider(matchId));
    final playState = ref.watch(matchPlayControllerProvider);

    // An async (6-hour) match is meant to be played across sittings, so leaving
    // the screen is NORMAL and must NOT forfeit: the game keeps running
    // server-side and the player returns to it via Resume. Only a live match
    // treats a mid-match exit as a forfeit.
    // Unknown mode (the doc has not loaded yet) counts as async here: with no
    // match there is nothing to forfeit, and trapping the player behind a
    // forfeit confirm during the load window is exactly the async-leave bug we
    // are guarding against. Only a loaded LIVE match forfeits on exit.
    final isAsync = match == null || match.settings.mode == MatchMode.async;

    return PopScope(
      // Live: intercept back (OS gesture included) and confirm the forfeit
      // instead of silently dropping the player out of the match. Async (or not
      // yet loaded): let back pop straight through; it just leaves the screen.
      canPop: isAsync,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return; // async popped cleanly, or a live pop already ran.
        final leave = await _confirmForfeit();
        if (leave && mounted) _leaveMatch();
      },
      child: Scaffold(
        backgroundColor: AppColors.transparent,
        body: PondBackground(
          child: SafeArea(
            child: _content(
              match,
              rack,
              effects,
              playState,
              myUid,
              failed,
              isAsync,
            ),
          ),
        ),
      ),
    );
  }

  /// Pond-styled confirm before abandoning a live match. Returns true when
  /// the player taps Forfeit.
  Future<bool> _confirmForfeit() async {
    final result = await showPondDialog<bool>(
      context: context,
      title: 'Leave the match?',
      body: 'Leaving now forfeits the match.',
      actions: [
        PondPillButton(
          label: 'Stay',
          variant: PondPillVariant.quiet,
          onPressed: () =>
              Navigator.of(context, rootNavigator: true).pop(false),
        ),
        PondPillButton(
          label: 'Forfeit',
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
        ),
      ],
    );
    return result ?? false;
  }

  /// Forfeit: get off the page first (disposing this page's match-stream
  /// listener before the status flip lands), then fire the leave without
  /// awaiting; an offline failure must never trap the player behind the
  /// PopScope.
  void _leaveMatch() {
    final service = ref.read(matchServiceProvider);
    context.go('/');
    service.leave(widget.matchId).ignore();
  }

  /// Which SLOTS are frozen at [now]: every slot whose letter equals the
  /// server-frozen character, so a shuffle never desyncs the freeze from the
  /// letter it targets.
  Set<int> _frozenSlots(
    MatchActiveEffects effects,
    List<String> wheelLetters,
    int now,
  ) {
    final letter = effects.frozenLetter;
    final until = effects.freezeUntil;
    if (letter == null || until == null || until.millisecondsSinceEpoch <= now) {
      return const <int>{};
    }
    final frozen = <int>{};
    for (var slot = 0; slot < wheelLetters.length; slot++) {
      if (wheelLetters[slot].toUpperCase() == letter.toUpperCase()) {
        frozen.add(slot);
      }
    }
    return frozen;
  }

  List<int> _orderOf(MatchRack rack, MatchPlayState playState) {
    _refreshWheel(rack, playState);
    return _order!;
  }

  List<String> _wheelLettersOf(MatchRack rack, MatchPlayState playState) {
    _refreshWheel(rack, playState);
    return _wheelLetters!;
  }

  void _refreshWheel(MatchRack rack, MatchPlayState playState) {
    if (identical(rack, _wheelRackKey) &&
        identical(playState.rackOrder, _wheelOrderKey) &&
        _order != null) {
      return;
    }
    _wheelRackKey = rack;
    _wheelOrderKey = playState.rackOrder;
    _order = playState.rackOrder.length == rack.letters.length
        ? playState.rackOrder
        : List<int>.generate(rack.letters.length, (i) => i);
    _wheelLetters = [for (final i in _order!) rack.letters[i]];
  }

  Set<String> _foundOf(MatchRack rack, MatchPlayState playState) {
    if (identical(rack, _foundRackKey) &&
        identical(playState.pendingFound, _foundPendingKey) &&
        _found != null) {
      return _found!;
    }
    _foundRackKey = rack;
    _foundPendingKey = playState.pendingFound;
    return _found = <String>{
      ...rack.foundWords.map((w) => w.toUpperCase()),
      ...playState.pendingFound,
    };
  }

  /// `rack.targets` sorts on every read, so hold the board's copy until the rack
  /// itself changes.
  List<PuzzleAnswer> _targetsOf(MatchRack rack) {
    if (identical(rack, _targetsKey) && _targets != null) return _targets!;
    _targetsKey = rack;
    return _targets = [
      for (final a in rack.targets)
        PuzzleAnswer(word: a.word, length: a.length, definition: null),
    ];
  }

  Widget _content(
    Match? match,
    MatchRack? rack,
    MatchActiveEffects effects,
    MatchPlayState playState,
    String? myUid,
    bool failed,
    bool isAsync,
  ) {
    if (failed) {
      return MatchLoadError(
        onRetry: () {
          ref.invalidate(matchStreamProvider(widget.matchId));
          ref.invalidate(myRackStreamProvider(widget.matchId));
        },
      );
    }
    if (match == null || rack == null) {
      return const Center(child: CircularProgressIndicator());
    }
    // Pre-start: the lobby, or the shared countdown to startedAt. The board opens
    // on the clock (see Match.playableAt) rather than on status == active, which
    // the server cannot reach until someone submits.
    if (match.status == MatchStatus.lobby || match.countingDownAt(_now)) {
      return _MatchInterlude(
        label: 'Get ready',
        countdown: match.countdownSecondsAt(_now),
      );
    }
    // Time is up but the server has not finalized yet (it finalizes on the next
    // settle). Hold rather than leave a dead board on screen; the finished
    // listener navigates to the result as soon as the doc lands.
    if (!match.playableAt(_now) && match.status != MatchStatus.finished) {
      return const _MatchInterlude(label: "Time's up");
    }
    if (!rack.decrypted) {
      return const Center(
        child: Text(
          'Preparing your rack...',
          style: TextStyle(color: AppColors.padLabelSoft),
        ),
      );
    }

    final controller = ref.read(matchPlayControllerProvider.notifier);
    final order = _orderOf(rack, playState);
    final wheelLetters = _wheelLettersOf(rack, playState);
    final found = _foundOf(rack, playState);
    final revealed = playState.revealed;
    final targets = _targetsOf(rack);
    final catalog = ref.watch(storeCatalogProvider).value ?? const <StoreItem>[];
    final inventory =
        ref.watch(inventoryControllerProvider).value ?? const <String, int>{};
    final prices = {for (final item in catalog) item.id: item.cost};

    final myScore = myUid == null ? 0 : (match.playerFor(myUid)?.score ?? 0);
    final formed = [
      for (final s in playState.selection) wheelLetters[s],
    ].join().toUpperCase();

    final playColumn = Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: MatchHud(
            myScore: myScore,
            myWords: rack.foundWords.length,
            opponentName:
                (myUid == null ? null : match.opponentOf(myUid)?.displayName) ??
                'Waiting...',
            opponentWords:
                myUid == null ? 0 : (match.opponentOf(myUid)?.wordsFound ?? 0),
            opponentConnected:
                myUid == null ? false : (match.opponentOf(myUid)?.connected ?? false),
            // Per-player deadline: endsAt plus MY banked time_boost bonus.
            // Raw endsAt would expire the countdown early for a boosted player.
            endsAt: DateTime.fromMillisecondsSinceEpoch(
              myUid == null ? match.endsAt : match.deadlineFor(myUid),
            ),
            now: () => ref.read(serverClockProvider).now(),
            onDictionary: () => showDictionarySheet(
              context,
              targets: targets,
              found: found,
              revealed: revealed,
            ),
            onForfeit: isAsync
                ? () async {
                    final leave = await _confirmForfeit();
                    if (leave && mounted) _leaveMatch();
                  }
                : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _Ticking(
              now: () => ref.read(serverClockProvider).now(),
              builder: (_, now, __) =>
                  ActiveEffectChips(effects: effects, nowMillis: now),
            ),
          ),
        ),
        Expanded(
          child: _Ticking(
            now: () => ref.read(serverClockProvider).now(),
            child: WordBoard(
              targets: targets,
              found: found,
              revealed: revealed,
              center: true,
            ),
            builder: (_, now, board) => FogOverlay(
              active:
                  effects.fogUntil != null &&
                  effects.fogUntil!.millisecondsSinceEpoch > now,
              child: board!,
            ),
          ),
        ),
        FormedWordPill(word: formed),
        const SizedBox(height: AppSpacing.sm),
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
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
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PowerupSideButtons(
                          onOpen: (category) =>
                              setState(() => _openPowerupCategory = category),
                          offenseKey: powerupOffenseButtonKey,
                          defenseKey: powerupDefenseButtonKey,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        WheelActionButton(
                          icon: Icons.shuffle,
                          semanticLabel: 'Shuffle',
                          onTap: controller.shuffle,
                        ),
                      ],
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
                            onTouch: (slot) => controller.touchLetter(
                              slot,
                              frozen: _frozenSlots(
                                effects,
                                wheelLetters,
                                ref
                                    .read(serverClockProvider)
                                    .now()
                                    .millisecondsSinceEpoch,
                              ),
                            ),
                            onEnd: () {
                              final word = controller.endSelection(rack, found);
                              if (word != null) _submit(word);
                            },
                          ),
                          Positioned.fill(
                            child: _Ticking(
                              now: () => ref.read(serverClockProvider).now(),
                              builder: (_, now, __) => FrozenLetterOverlay(
                                frozenSlots: _frozenSlots(
                                  effects,
                                  wheelLetters,
                                  now,
                                ),
                                letterCount: wheelLetters.length,
                                size: _wheelSize,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    // Hint always shows (client-only, no cost). Live matches
                    // additionally stack the forfeit flag below it, gating on the
                    // same confirm as back; async matches instead surface their
                    // forfeit affordance in the HUD (MatchHud's sword icon, since
                    // leaving an async match by itself is normal and must not
                    // forfeit), so the gap keeps the wheel centered.
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        WheelActionButton(
                          iconAsset: 'assets/powerups/hint.svg',
                          semanticLabel: 'Hint',
                          onTap: () => controller.hint(rack, found),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (isAsync)
                          const SizedBox(width: AppSizing.actionButton)
                        else
                          WheelActionButton(
                            icon: Icons.flag_outlined,
                            semanticLabel: 'Leave match',
                            onTap: () async {
                              final leave = await _confirmForfeit();
                              if (leave && mounted) _leaveMatch();
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_openPowerupCategory != null)
              PowerupWheel(
                category: _openPowerupCategory!,
                ownedCounts: inventory,
                prices: prices,
                firstSlotKey: powerupWheelSlotKey,
                onFire: _firePowerup,
                onTapInfo: (itemId) => _openPowerupInfo(catalog, itemId),
                onClose: () => setState(() => _openPowerupCategory = null),
              ),
            if (_activeBanner != null)
              PowerupIncomingBanner(
                key: ValueKey(_activeBanner),
                data: _activeBanner!,
                onDone: _onBannerDone,
              ),
          ],
        ),
      ],
    );

    // Task 8: the first-time powerup walkthrough, mounted only while the match
    // is actually playable (all pre-play/holding branches returned above). It
    // renders nothing once powerupTutorialSeen is set.
    return Stack(
      children: [
        playColumn,
        Positioned.fill(
          child: PowerupTutorialOverlay(
            offenseKey: powerupOffenseButtonKey,
            defenseKey: powerupDefenseButtonKey,
            wheelSlotKey: powerupWheelSlotKey,
            onOpenOffenseWheel: () => setState(
              () => _openPowerupCategory = PowerupCategory.offense,
            ),
            onCloseWheel: () => setState(() => _openPowerupCategory = null),
          ),
        ),
      ],
    );
  }
}

/// The pre-play and post-play holding screen: the app mark drawing itself on a
/// loop, with the label under it and the shared countdown when there is one.
/// Replaces the bare "Get ready..." text, which sat dead on screen.
class _MatchInterlude extends StatelessWidget {
  const _MatchInterlude({required this.label, this.countdown = 0});

  final String label;

  /// Whole seconds until the shared start instant; 0 hides the numeral.
  final int countdown;

  /// Diameter of the drawing mark.
  static const double _markSize = 160;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const AnimatedAppIcon(size: _markSize),
          const SizedBox(height: AppSpacing.xl),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.wordmark,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (countdown > 0) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$countdown',
              style: const TextStyle(
                color: AppColors.wordmark,
                fontSize: 44,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
