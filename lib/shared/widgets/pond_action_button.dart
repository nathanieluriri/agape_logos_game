// lib/shared/widgets/pond_action_button.dart
import 'package:flutter/widgets.dart';

import '../../core/design/motion/curves.dart';
import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/durations.dart';
import '../../core/design/tokens/gradients.dart';
import '../../core/design/tokens/radii.dart';
import '../../core/design/tokens/shadows.dart';
import '../../core/design/tokens/spacing.dart';
import '../../core/haptics/haptics.dart';
import 'glyphs/pond_glyph.dart';

/// A full-width primary choice row in the pad design language: a deep-water
/// card with a recessed glyph disc and a bold label. The third member of the
/// button set, next to PondPillButton (compact actions) and LilyPadButton
/// (floating pads). Scales down on press; no Material ink.
class PondActionButton extends StatefulWidget {
  const PondActionButton({
    super.key,
    required this.glyph,
    required this.label,
    required this.onPressed,
    this.glyphOverride,
  });

  final PondGlyph glyph;
  final String label;
  final VoidCallback onPressed;

  /// When set, this widget is shown in the glyph disc instead of the painted
  /// [glyph] (used for the SVG VS mark). [glyph] stays the fallback.
  final Widget? glyphOverride;

  @override
  State<PondActionButton> createState() => _PondActionButtonState();
}

class _PondActionButtonState extends State<PondActionButton> {
  /// Outer diameter of the recessed glyph disc, halo ring included.
  static const double _disc = 44;

  /// Halo ring thickness around the glyph disc (matches the settings gear).
  static const double _haloPadding = 4;

  /// Glyph size inside the disc.
  static const double _glyphSize = 22;

  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {
          setState(() => _pressed = false);
          Haptics.instance.lightImpact();
          widget.onPressed();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1.0,
          duration: AppDurations.instant,
          curve: AppCurves.emphasized,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: AppGradients.pondCard,
              borderRadius: AppRadii.card,
              border: Border.all(color: AppColors.settingsBorder),
              boxShadow: AppShadows.pill,
            ),
            child: ExcludeSemantics(
              child: Row(
                children: [
                  Container(
                    width: _disc,
                    height: _disc,
                    padding: const EdgeInsets.all(_haloPadding),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.settingsHalo,
                    ),
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppGradients.settingsInner,
                      ),
                      child: Center(
                        child: widget.glyphOverride ??
                            PondIcon(widget.glyph, size: _glyphSize),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: AppColors.padLabel,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
