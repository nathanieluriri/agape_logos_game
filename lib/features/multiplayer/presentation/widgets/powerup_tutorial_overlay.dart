import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/motion/curves.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/durations.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../tutorial/application/powerup_tutorial_controller.dart';
import '../../../tutorial/presentation/widgets/spotlight_scrim.dart';
import '../../../tutorial/presentation/widgets/tutorial_hand.dart';
import '../../../tutorial/presentation/widgets/tutorial_message_pill.dart';
import '../../../tutorial/presentation/widgets/tutorial_trace.dart';

/// The first-time powerup walkthrough: a spotlight scrim cut out around the
/// current step's anchor (offense button, first wheel slot, defense button),
/// a coach pill, and on the drag step a looping hand tracing the pull out of
/// the wheel. A tap anywhere advances; Skip (or finishing) persists the
/// `powerupTutorialSeen` flag once via [powerupTutorialProvider].
///
/// Renders nothing while the provider is null. The match page mounts this only
/// while a match is actually playable, so the tutorial can never fire from a
/// lobby, countdown, or finished screen.
class PowerupTutorialOverlay extends ConsumerStatefulWidget {
  const PowerupTutorialOverlay({
    super.key,
    required this.offenseKey,
    required this.defenseKey,
    required this.wheelSlotKey,
    required this.onOpenOffenseWheel,
    required this.onCloseWheel,
  });

  /// Anchors exposed by the match page's powerup widgets. [wheelSlotKey] is
  /// mounted only while a wheel is open, so the drag step first asks the page
  /// to open the offense wheel via [onOpenOffenseWheel].
  final GlobalKey offenseKey;
  final GlobalKey defenseKey;
  final GlobalKey wheelSlotKey;

  final VoidCallback onOpenOffenseWheel;
  final VoidCallback onCloseWheel;

  @override
  ConsumerState<PowerupTutorialOverlay> createState() =>
      _PowerupTutorialOverlayState();
}

class _PowerupTutorialOverlayState
    extends ConsumerState<PowerupTutorialOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: AppDurations.tutorialTrace,
  );

  Rect? _targetRect;

  /// How far (in slot heights) the hand pulls the powerup out of the wheel.
  static const double _dragSlotHeights = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(powerupTutorialProvider.notifier).maybeStart();
    });
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  GlobalKey _keyFor(PowerupTutorialStep step) => switch (step) {
        PowerupTutorialStep.offense => widget.offenseKey,
        PowerupTutorialStep.wheelDrag => widget.wheelSlotKey,
        PowerupTutorialStep.defense => widget.defenseKey,
      };

  String _messageFor(PowerupTutorialStep step) => switch (step) {
        PowerupTutorialStep.offense => 'Attack your opponent',
        PowerupTutorialStep.wheelDrag =>
          'Drag a powerup onto the board to use it',
        PowerupTutorialStep.defense => 'Protect yourself the same way',
      };

  /// Ask the page to open/close the offense wheel around the drag step, and
  /// reset the resolved rect so the new step's anchor is measured fresh.
  void _onStepChanged(PowerupTutorialStep? prev, PowerupTutorialStep? next) {
    if (next == PowerupTutorialStep.wheelDrag) widget.onOpenOffenseWheel();
    if (prev == PowerupTutorialStep.wheelDrag) widget.onCloseWheel();
    _targetRect = null;
  }

  /// Post-frame: the current anchor's bounds in overlay coordinates. Both
  /// corners are mapped so ancestor scaling (the page's FittedBox) is honored.
  void _resolveRect(PowerupTutorialStep step) {
    if (!mounted) return;
    final overlay = context.findRenderObject();
    final box = _keyFor(step).currentContext?.findRenderObject();
    if (overlay is! RenderBox || !overlay.hasSize) return;
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    final topLeft = overlay.globalToLocal(box.localToGlobal(Offset.zero));
    final bottomRight = overlay.globalToLocal(
      box.localToGlobal(box.size.bottomRight(Offset.zero)),
    );
    final rect = Rect.fromPoints(topLeft, bottomRight);
    if (rect != _targetRect) setState(() => _targetRect = rect);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PowerupTutorialStep?>(powerupTutorialProvider, _onStepChanged);
    final step = ref.watch(powerupTutorialProvider);
    if (step == null) {
      if (_loop.isAnimating) _loop.stop();
      return const SizedBox.shrink();
    }
    // Anchors mount and settle over the next frame (the wheel slot only exists
    // once the wheel opens), so re-resolve after every build of this overlay.
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveRect(step));

    final rect = _targetRect;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    // The hand's drag path on the wheel step: from the slot center straight up
    // and out of the wheel, toward the board.
    List<Offset>? dragPoints;
    if (step == PowerupTutorialStep.wheelDrag && rect != null) {
      dragPoints = [
        rect.center,
        rect.center - Offset(0, rect.height * _dragSlotHeights),
      ];
    }
    if (dragPoints != null && !reduceMotion) {
      if (!_loop.isAnimating) _loop.repeat();
    } else if (_loop.isAnimating) {
      _loop.stop();
    }

    final notifier = ref.read(powerupTutorialProvider.notifier);
    return Stack(
      children: [
        // Tap anywhere advances. Opaque: the tutorial is modal, nothing
        // underneath is interactive until it is finished or skipped.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: notifier.advance,
            child: CustomPaint(
              painter: SpotlightScrimPainter(
                cutouts: SpotlightCutouts(wheelRect: rect),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        if (dragPoints != null) ...[
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: TutorialTracePainter(points: dragPoints),
              ),
            ),
          ),
          _HandAlongDrag(
            points: dragPoints,
            loop: _loop,
            reduceMotion: reduceMotion,
          ),
        ],
        Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: TutorialMessagePill(message: _messageFor(step)),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: AppSpacing.lg,
          child: Center(
            child: TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.pillText),
              onPressed: notifier.dismiss,
              child: const Text('Skip'),
            ),
          ),
        ),
      ],
    );
  }
}

/// The pointing hand riding the drag guide: eased along the path once per
/// loop, or parked on the slot under reduced motion.
class _HandAlongDrag extends StatelessWidget {
  const _HandAlongDrag({
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
