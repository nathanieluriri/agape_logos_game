import 'package:flutter/material.dart';

import '../../../../core/design/motion/curves.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/durations.dart';
import '../../../../core/design/tokens/gradients.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/shadows.dart';
import '../../../../core/design/tokens/sizing.dart';
import '../../../../core/design/tokens/typography.dart';
import '../../../../core/haptics/haptics.dart';
import '../../../puzzles/domain/puzzle.dart';

/// The target-word board: one row per answer, cells fill in as words are found
/// (or hint-revealed). Finding a word plays a left-to-right staggered bloom:
/// each tile scales in with an overshoot, lifts, morphs from a submerged slot
/// into a mini lily pad, and pops its letter in just after the pad fills.
class WordBoard extends StatelessWidget {
  const WordBoard({
    super.key,
    required this.targets,
    required this.found,
    required this.revealed,
    this.center = false,
  });

  final List<PuzzleAnswer> targets;
  final Set<String> found;
  final Map<String, int> revealed;

  /// When true the rows sit vertically centered in the available height (and
  /// still scroll if they overflow it). The in-game board sets this so short
  /// puzzles don't strand a big empty gap below the words; left false elsewhere.
  final bool center;

  @override
  Widget build(BuildContext context) {
    final column = Column(
      mainAxisAlignment: center
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final answer in targets)
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSizing.boardTileGap / 2,
            ),
            child: _WordRow(
              word: answer.word.toUpperCase(),
              found: found.contains(answer.word.toUpperCase()),
              revealed: revealed[answer.word.toUpperCase()] ?? 0,
            ),
          ),
      ],
    );
    if (!center) return SingleChildScrollView(child: column);
    // Center within the region, but keep a scroll fallback for tall puzzles by
    // floor-ing the content to the viewport height.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : 0,
          ),
          child: column,
        ),
      ),
    );
  }
}

/// One answer's row. Owns the found-transition detection so a completed word
/// cascades left to right (each tile delayed by [AppDurations.tileStagger] *
/// its index) while a single hint reveal fills its one tile with no delay. The
/// row is wrapped in a [RepaintBoundary] so a tile blooming does not repaint
/// the rest of the board.
class _WordRow extends StatefulWidget {
  const _WordRow({
    required this.word,
    required this.found,
    required this.revealed,
  });

  final String word;
  final bool found;
  final int revealed;

  @override
  State<_WordRow> createState() => _WordRowState();
}

class _WordRowState extends State<_WordRow> {
  /// True only on the build where this word just flipped to found, so the tiles
  /// that fill this frame cascade; every other build (a lone hint reveal, an
  /// unrelated board rebuild, the initial already-found paint) uses no delay.
  bool _cascading = false;

  @override
  void didUpdateWidget(covariant _WordRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _cascading = widget.found && !oldWidget.found;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < widget.word.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizing.boardTileGap / 2,
              ),
              child: _AnimatedTile(
                letter: widget.word[i],
                filled: widget.found || i < widget.revealed,
                revealDelay: _cascading
                    ? AppDurations.tileStagger * i
                    : Duration.zero,
              ),
            ),
        ],
      ),
    );
  }
}

/// A single board cell. Empty it is a submerged hollow; filled it is a mini
/// lily pad carrying its letter. The empty -> filled transition is a premium
/// reveal driven by one [AnimationController]: the pad blooms up out of the slot
/// (scale-in with an overshoot + a gentle lift) and the glyph pops in just
/// behind it. [revealDelay] front-loads dead time into the controller so a row
/// cascades without any timers.
class _AnimatedTile extends StatefulWidget {
  const _AnimatedTile({
    required this.letter,
    required this.filled,
    required this.revealDelay,
  });

  final String letter;
  final bool filled;
  final Duration revealDelay;

  @override
  State<_AnimatedTile> createState() => _AnimatedTileState();
}

class _AnimatedTileState extends State<_AnimatedTile>
    with SingleTickerProviderStateMixin {
  /// Created lazily: an unfound cell is a static slot that never animates, so it
  /// never pays for a ticker. Kept NULLABLE (not `late final`) on purpose: a
  /// `late final` initializer would run on the first read, and [dispose] reads
  /// it, so an unfound tile would construct an AnimationController while its
  /// element is already deactivated. `createTicker` then looks up the TickerMode
  /// inherited widget and asserts "Looking up a deactivated widget's ancestor is
  /// unsafe". Read through [_controller]; dispose through [_c].
  AnimationController? _c;

  AnimationController get _controller => _c ??= AnimationController(
    vsync: this,
    duration: AppDurations.tileReveal,
  );

  /// Fraction of the (delay + reveal) window spent waiting before the reveal
  /// begins; 0 when there is no stagger delay.
  double _revealStart = 0;

  /// How far the pad lifts as it blooms (logical px, eased to 0).
  static const double _riseFrom = 10;

  /// Where in the reveal the glyph starts popping (after the pad has begun
  /// filling) and where the pad finishes blooming, as fractions of the reveal.
  static const double _glyphStart = 0.45;
  static const double _padWindow = 0.72;

  /// Mini-pad depth: the hard darker underside edge first, then the soft cast
  /// shadow on the water (the pad painter's layer recipe).
  static const _filledShadows = <BoxShadow>[
    BoxShadow(color: AppColors.lilyGreenUnder, offset: Offset(0, 3)),
    ...AppShadows.pad,
  ];

  /// Filled cell: a mini lily pad resting on the water.
  static const _filledDecoration = BoxDecoration(
    gradient: AppGradients.lilyGreen,
    borderRadius: AppRadii.card,
    boxShadow: _filledShadows,
  );

  /// Empty cell: a submerged hollow in the water.
  static const _emptyDecoration = BoxDecoration(
    color: AppColors.boardSlotFill,
    borderRadius: AppRadii.card,
    border: Border.fromBorderSide(BorderSide(color: AppColors.boardSlotBorder)),
  );

  @override
  void initState() {
    super.initState();
    // Born already filled (a found word on first paint, or a golden snapshot):
    // show the finished pad with no animation.
    if (widget.filled) _controller.value = 1;
  }

  @override
  void didUpdateWidget(covariant _AnimatedTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.filled && widget.filled) {
      // Tick exactly on the empty -> filled flip (a letter landing), whether
      // from a found word or a hint reveal. Not on first build, so a board that
      // mounts with words already found stays quiet. Mute-aware via the shared
      // service.
      // PLAN (plans 07+08 merged): plan 07's stagger delays the VISUAL bloom
      // but all tiles of a found word flip `filled` on the same frame, so the
      // ticks of a cascade fire together while the pads bloom in sequence. If
      // that reads as one mush on device, move this tick into _startReveal's
      // reveal window (fire when the controller passes _revealStart).
      Haptics.instance.tickImpact();
      _startReveal();
    } else if (oldWidget.filled && !widget.filled) {
      // Cells never un-fill in play; keep state coherent if it ever happens.
      _controller.value = 0;
      _revealStart = 0;
    }
  }

  void _startReveal() {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller
        ..duration = AppDurations.tileReveal
        ..value = 1;
      return;
    }
    final total = widget.revealDelay + AppDurations.tileReveal;
    _controller.duration = total;
    _revealStart = total.inMicroseconds == 0
        ? 0
        : widget.revealDelay.inMicroseconds / total.inMicroseconds;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    // Never `_controller` here: that would construct one for a tile that never
    // animated. Only dispose a controller that actually exists.
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // An empty, never-flipped cell is a static slot: no controller runs and no
    // glyph is in the tree, so unfound cells stay truly blank.
    if (!widget.filled) {
      return const SizedBox(
        width: AppSizing.boardTile,
        height: AppSizing.boardTile,
        child: DecoratedBox(decoration: _emptyDecoration),
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // Reveal progress after the leading stagger delay.
        // PLAN: at rest (p == 1) scale/rise/glyphT resolve to exactly 1/0/1,
        // so the finished tile matches today's filled tile pixel-for-pixel.
        // Tune _riseFrom, _glyphStart, _padWindow on-device only if the bloom
        // feels off; timing lives in the AppDurations tokens.
        final raw = _controller.value;
        final p = _revealStart >= 1
            ? 1.0
            : ((raw - _revealStart) / (1 - _revealStart)).clamp(0.0, 1.0);

        final bloom = (p / _padWindow).clamp(0.0, 1.0);
        // Pad grows from 0 with an overshoot, so it is naturally invisible while
        // it waits and no Opacity layer is needed in this hot path.
        final scale = AppCurves.pop.transform(bloom);
        final rise = _lerp(_riseFrom, 0, AppCurves.enter.transform(bloom));
        final glyphT = p <= _glyphStart
            ? 0.0
            : AppCurves.pop.transform(
                ((p - _glyphStart) / (1 - _glyphStart)).clamp(0.0, 1.0),
              );

        return SizedBox(
          width: AppSizing.boardTile,
          height: AppSizing.boardTile,
          child: Stack(
            fit: StackFit.expand,
            // Let the pad's bloom overshoot spill past the slot edge.
            clipBehavior: Clip.none,
            children: [
              // The empty slot sits behind the growing pad; once the pad fully
              // covers it (p == 1) it is dropped so the resting cell is
              // pixel-identical to the old filled tile.
              if (p < 1) const DecoratedBox(decoration: _emptyDecoration),
              Transform.translate(
                offset: Offset(0, rise),
                child: Transform.scale(
                  scale: scale,
                  child: DecoratedBox(
                    decoration: _filledDecoration,
                    child: Center(
                      child: Transform.scale(
                        scale: glyphT,
                        child: Text(
                          widget.letter,
                          style: AppTypography.tileLetter.copyWith(
                            color: AppColors.padLabel,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}
