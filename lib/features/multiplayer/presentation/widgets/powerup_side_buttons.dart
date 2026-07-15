// lib/features/multiplayer/presentation/widgets/powerup_side_buttons.dart
import 'package:flutter/material.dart';

import '../../../../core/design/motion/curves.dart';
import '../../../../core/design/tokens/durations.dart';
import '../../../../core/design/tokens/gradients.dart';
import '../../../../core/design/tokens/shadows.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../core/haptics/haptics.dart';
import '../../../../shared/widgets/glyphs/pond_glyph.dart';
import 'powerup_wheel.dart';

/// Two round buttons, stacked above the shuffle button: offense (swords) and
/// defense (shield), each opening the matching [PowerupWheel] category. Same
/// cream-disc chrome family as the shuffle FAB, drawn with hand-painted
/// [PondIcon] glyphs (no [Icons]).
class PowerupSideButtons extends StatelessWidget {
  const PowerupSideButtons({
    super.key,
    required this.onOpen,
    this.offenseKey,
    this.defenseKey,
  });

  final void Function(PowerupCategory category) onOpen;

  /// Tutorial spotlight anchors.
  final GlobalKey? offenseKey;
  final GlobalKey? defenseKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundGlyphButton(
          key: offenseKey,
          glyph: PondGlyph.swords,
          semanticLabel: 'Offense powerups',
          onTap: () => onOpen(PowerupCategory.offense),
        ),
        const SizedBox(height: AppSpacing.sm),
        _RoundGlyphButton(
          key: defenseKey,
          glyph: PondGlyph.shield,
          semanticLabel: 'Defense powerups',
          onTap: () => onOpen(PowerupCategory.defense),
        ),
      ],
    );
  }
}

class _RoundGlyphButton extends StatefulWidget {
  const _RoundGlyphButton({
    super.key,
    required this.glyph,
    required this.semanticLabel,
    required this.onTap,
  });

  final PondGlyph glyph;
  final String semanticLabel;
  final VoidCallback onTap;

  static const double _size = 44;

  @override
  State<_RoundGlyphButton> createState() => _RoundGlyphButtonState();
}

class _RoundGlyphButtonState extends State<_RoundGlyphButton> {
  static const _discDecoration = BoxDecoration(
    shape: BoxShape.circle,
    gradient: AppGradients.wheelPad,
    boxShadow: AppShadows.pill,
  );

  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {
          setState(() => _pressed = false);
          Haptics.instance.gameImpact();
          widget.onTap();
        },
        child: ExcludeSemantics(
          child: AnimatedScale(
            scale: _pressed ? 0.92 : 1.0,
            duration: reduceMotion ? Duration.zero : AppDurations.instant,
            curve: AppCurves.emphasized,
            child: Container(
              width: _RoundGlyphButton._size,
              height: _RoundGlyphButton._size,
              alignment: Alignment.center,
              decoration: _discDecoration,
              child: PondIcon(widget.glyph, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}
