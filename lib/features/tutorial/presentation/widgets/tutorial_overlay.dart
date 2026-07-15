import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/motion/curves.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/durations.dart';
import '../../../../core/design/tokens/sizing.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../game/application/game_controller.dart';
import '../../../game/presentation/widgets/letter_wheel.dart';
import '../../application/tutorial_controller.dart';
import '../../application/tutorial_state.dart';
import 'spotlight_scrim.dart';
import 'tutorial_hand.dart';
import 'tutorial_message_pill.dart';
import 'tutorial_trace.dart';

/// The first-play tutorial spotlight: a near-black scrim with cutouts around
/// the letter wheel and word board, a coach pill, a dashed guide through the
/// target word's letters, and a looping pointing hand. Input is blocked
/// everywhere except inside the wheel cutout.
///
/// Renders nothing while [tutorialProvider] is null, but must be built
/// whenever a game session exists: watching the provider is what wires the
/// tutorial controller's listeners.
class TutorialOverlay extends ConsumerStatefulWidget {
  const TutorialOverlay({
    super.key,
    required this.wheelKey,
    required this.boardKey,
  });

  /// Keys on the page's [LetterWheel] and word board, used to resolve their
  /// on-screen bounds into overlay coordinates after layout.
  final GlobalKey wheelKey;
  final GlobalKey boardKey;

  @override
  ConsumerState<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends ConsumerState<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: AppDurations.tutorialTrace,
  );

  Timer? _celebrateTimer;
  Rect? _wheelRect;
  Rect? _boardRect;

  /// Everything the wheel/board geometry can actually depend on. Resolving the
  /// rects walks two render trees, so it must not run on every frame: it runs
  /// only when this key changes (mount, relayout, step change, new rack).
  Object? _geometryKey;

  @override
  void dispose() {
    _celebrateTimer?.cancel();
    _loop.dispose();
    super.dispose();
  }

  /// [key]'s render box bounds mapped into the overlay's coordinate space.
  /// Uses both corners so ancestor scaling (the page's FittedBox) is honored.
  Rect? _rectFor(GlobalKey key, RenderBox overlay) {
    final box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    final topLeft = overlay.globalToLocal(box.localToGlobal(Offset.zero));
    final bottomRight = overlay.globalToLocal(
      box.localToGlobal(box.size.bottomRight(Offset.zero)),
    );
    return Rect.fromPoints(topLeft, bottomRight);
  }

  /// Post-frame: resolve wheel/board rects and rebuild only when they moved.
  void _resolveRects() {
    if (!mounted) return;
    final overlay = context.findRenderObject();
    if (overlay is! RenderBox || !overlay.hasSize) return;
    final wheel = _rectFor(widget.wheelKey, overlay);
    final board = _rectFor(widget.boardKey, overlay);
    if (wheel != _wheelRect || board != _boardRect) {
      setState(() {
        _wheelRect = wheel;
        _boardRect = board;
      });
    }
  }

  void _scheduleResolve(Object key) {
    if (key == _geometryKey) return;
    _geometryKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveRects());
  }

  /// Show the celebrate pill for its token duration, then retire the tutorial.
  void _onTutorialChanged(TutorialState? prev, TutorialState? next) {
    if (next?.phase == TutorialPhase.celebrate &&
        prev?.phase != TutorialPhase.celebrate) {
      _celebrateTimer?.cancel();
      _celebrateTimer = Timer(AppDurations.tutorialCelebrate, () {
        ref.read(tutorialProvider.notifier).dismissCelebration();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<TutorialState?>(tutorialProvider, _onTutorialChanged);
    final tutorial = ref.watch(tutorialProvider);
    // Only the fields this overlay reads, so a drag (which mutates the
    // session's selection) does not drag the rect resolve along with it.
    // wheelLetters is derived (a fresh list per call, so never equal under
    // select): watch the two fields it is derived from and read it instead.
    ref.watch(gameSessionProvider.select((s) => s?.puzzle));
    final rackOrder = ref.watch(
      gameSessionProvider.select((s) => s?.rackOrder),
    );
    // The hand loops only while the player is idle; a touch on the wheel hides
    // it (the dashed guide stays).
    final idle = ref.watch(
      gameSessionProvider.select((s) => s?.selection.isEmpty ?? true),
    );
    if (tutorial == null || rackOrder == null) {
      if (_loop.isAnimating) _loop.stop();
      return const SizedBox.shrink();
    }
    final wheelLetters = ref.read(gameSessionProvider)!.wheelLetters;

    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final tracing = tutorial.phase == TutorialPhase.trace;
    final wheelRect = _wheelRect;

    // Dashed guide through the target word's letters, in overlay coordinates.
    List<Offset>? tracePoints;
    if (tracing && wheelRect != null) {
      final slots = slotsForWord(wheelLetters, tutorial.targetWord);
      if (slots != null) {
        final centers = LetterWheel.centersIn(
          wheelRect.size,
          wheelLetters.length,
        );
        tracePoints = [for (final s in slots) wheelRect.topLeft + centers[s]];
      }
    }

    final showHand = tracePoints != null && idle;
    if (showHand && !reduceMotion) {
      if (!_loop.isAnimating) _loop.repeat();
    } else if (_loop.isAnimating) {
      _loop.stop();
    }

    final wheelRadius = wheelRect == null
        ? 0.0
        : wheelRect.shortestSide / 2 + AppSizing.tutorialCutoutPad;

    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          _scheduleResolve((
            constraints.biggest,
            tutorial.phase,
            rackOrder.length,
          ));
          return Stack(
            children: [
              Positioned.fill(
                child: SpotlightBarrier(
                  wheelCenter: wheelRect?.center,
                  wheelRadius: wheelRadius,
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: SpotlightScrimPainter(
                      cutouts: SpotlightCutouts(
                        wheelRect: wheelRect,
                        boardRect: _boardRect,
                      ),
                    ),
                  ),
                ),
              ),
              if (tracePoints != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: TutorialTracePainter(points: tracePoints),
                    ),
                  ),
                ),
              if (showHand)
                _HandAlongTrace(
                  points: tracePoints!,
                  loop: _loop,
                  reduceMotion: reduceMotion,
                ),
              _pill(tutorial, tracing, constraints.biggest, wheelRect),
              if (tracing)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: AppSpacing.lg,
                  child: Center(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.pillText,
                      ),
                      onPressed: () =>
                          ref.read(tutorialProvider.notifier).skip(),
                      child: const Text('Skip'),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// The coach pill: floating just above the wheel cutout while tracing,
  /// centered while celebrating (or until geometry resolves).
  Widget _pill(
    TutorialState tutorial,
    bool tracing,
    Size size,
    Rect? wheelRect,
  ) {
    final pill = IgnorePointer(
      child: Center(
        child: TutorialMessagePill(
          message: tutorial.message,
          highlight: tracing ? tutorial.targetWord : null,
        ),
      ),
    );
    if (!tracing || wheelRect == null) return Positioned.fill(child: pill);
    final cutoutTop =
        wheelRect.center.dy -
        (wheelRect.shortestSide / 2 + AppSizing.tutorialCutoutPad);
    return Positioned(
      left: AppSpacing.md,
      right: AppSpacing.md,
      bottom: size.height - cutoutTop + AppSpacing.md,
      child: pill,
    );
  }
}

/// The pointing hand riding the dashed guide: eased along the polyline once
/// per loop, or parked at the first letter under reduced motion.
class _HandAlongTrace extends StatelessWidget {
  const _HandAlongTrace({
    required this.points,
    required this.loop,
    required this.reduceMotion,
  });

  final List<Offset> points;
  final Animation<double> loop;
  final bool reduceMotion;

  Widget _at(Offset point) => Positioned(
    left: point.dx,
    top: point.dy,
    child: const IgnorePointer(child: TutorialHand()),
  );

  @override
  Widget build(BuildContext context) {
    if (reduceMotion) return _at(positionAlong(points, 0));
    return AnimatedBuilder(
      animation: loop,
      builder: (context, _) =>
          _at(positionAlong(points, AppCurves.float.transform(loop.value))),
    );
  }
}
