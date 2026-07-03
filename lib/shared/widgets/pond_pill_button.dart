// lib/shared/widgets/pond_pill_button.dart
import 'package:flutter/widgets.dart';

import '../../core/design/motion/curves.dart';
import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/durations.dart';
import '../../core/design/tokens/gradients.dart';
import '../../core/design/tokens/radii.dart';
import '../../core/design/tokens/shadows.dart';
import '../../core/design/tokens/sizing.dart';
import '../../core/design/tokens/spacing.dart';
import '../../core/haptics/haptics.dart';

/// Visual weight of a [PondPillButton].
enum PondPillVariant {
  /// Lily-green gradient capsule for the main action.
  primary,

  /// Translucent water capsule for secondary actions.
  quiet,

  /// Deep-red capsule for destructive actions.
  danger,
}

/// Capsule action button on the water chrome: a stadium pill with an optional
/// leading icon and a label. The app-wide stand-in for Material text/elevated
/// buttons. Scales down on press; no ink ripples.
class PondPillButton extends StatefulWidget {
  const PondPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = PondPillVariant.primary,
    this.icon,
    this.semanticLabel,
    this.enabled = true,
  });

  /// Text shown on the capsule.
  final String label;

  /// Called when the button is tapped.
  final VoidCallback onPressed;

  /// Visual weight; defaults to [PondPillVariant.primary].
  final PondPillVariant variant;

  /// Optional leading glyph.
  final IconData? icon;

  /// Accessibility label; falls back to [label].
  final String? semanticLabel;

  /// When false the pill ignores taps and dims (statically, no animation).
  final bool enabled;

  @override
  State<PondPillButton> createState() => _PondPillButtonState();
}

class _PondPillButtonState extends State<PondPillButton> {
  /// Leading icon diameter.
  static const double _iconSize = 20;

  /// Static dim applied while disabled; never animated, so this Opacity is
  /// not the hot-path kind CLAUDE.md warns about.
  static const double _disabledOpacity = 0.55;

  bool _pressed = false;

  void _handleTap() {
    setState(() => _pressed = false);
    // Weight the feedback to the action: destructive gets the heaviest.
    switch (widget.variant) {
      case PondPillVariant.danger:
        Haptics.instance.heavyImpact();
      case PondPillVariant.primary:
        Haptics.instance.mediumImpact();
      case PondPillVariant.quiet:
        Haptics.instance.lightImpact();
    }
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final style = _PillStyle.of(widget.variant);
    final pill = AnimatedScale(
      scale: _pressed ? 0.95 : 1.0,
      duration: AppDurations.instant,
      curve: AppCurves.emphasized,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizing.pillButtonHeight),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: style.fill,
            gradient: style.gradient,
            borderRadius: AppRadii.pill,
            border: Border.all(
              color: style.border,
              width: style.borderWidth,
            ),
            boxShadow: AppShadows.pill,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: ExcludeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      color: style.foreground,
                      size: _iconSize,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: style.foreground,
                      fontSize: 16,
                      fontWeight: style.weight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.semanticLabel ?? widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown:
            widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.enabled ? _handleTap : null,
        child: widget.enabled
            ? pill
            : Opacity(opacity: _disabledOpacity, child: pill),
      ),
    );
  }
}

/// Per-variant fill, border, and foreground styling for [PondPillButton].
class _PillStyle {
  const _PillStyle({
    this.fill,
    this.gradient,
    required this.border,
    this.borderWidth = 1,
    required this.foreground,
    required this.weight,
  });

  final Color? fill;
  final Gradient? gradient;
  final Color border;
  final double borderWidth;
  final Color foreground;
  final FontWeight weight;

  static const primary = _PillStyle(
    gradient: AppGradients.lilyGreen,
    border: AppColors.plusButtonBorder,
    borderWidth: 2,
    foreground: AppColors.padLabel,
    weight: FontWeight.w800,
  );

  static const quiet = _PillStyle(
    fill: AppColors.pillFill,
    border: AppColors.settingsBorder,
    foreground: AppColors.padLabel,
    weight: FontWeight.w700,
  );

  static const danger = _PillStyle(
    fill: AppColors.dangerFill,
    border: AppColors.dangerBorder,
    foreground: AppColors.dangerOnPond,
    weight: FontWeight.w800,
  );

  static _PillStyle of(PondPillVariant variant) => switch (variant) {
        PondPillVariant.primary => primary,
        PondPillVariant.quiet => quiet,
        PondPillVariant.danger => danger,
      };
}
