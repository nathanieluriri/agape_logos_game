// lib/shared/widgets/pond_text_link.dart
import 'package:flutter/widgets.dart';

import '../../core/design/motion/curves.dart';
import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/durations.dart';
import '../../core/design/tokens/spacing.dart';
import '../../core/haptics/haptics.dart';

/// Quiet centered text action on the water chrome: the app-wide stand-in for
/// [TextButton]. Scales down slightly on press; no ink ripples. Padding keeps
/// the tap target comfortable even though the label is small.
class PondTextLink extends StatefulWidget {
  const PondTextLink({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  /// The link text.
  final String label;

  /// Called when the link is tapped.
  final VoidCallback onTap;

  /// When false the link ignores taps and dims (statically, no animation).
  final bool enabled;

  @override
  State<PondTextLink> createState() => _PondTextLinkState();
}

class _PondTextLinkState extends State<PondTextLink> {
  /// Static dim applied while disabled; never animated, so this Opacity is
  /// not the hot-path kind CLAUDE.md warns about.
  static const double _disabledOpacity = 0.55;

  bool _pressed = false;

  void _handleTap() {
    setState(() => _pressed = false);
    Haptics.instance.lightImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final text = AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: AppDurations.instant,
      curve: AppCurves.emphasized,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.md,
        ),
        child: ExcludeSemantics(
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.padLabelSoft,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown:
            widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.enabled ? _handleTap : null,
        child: widget.enabled
            ? text
            : Opacity(opacity: _disabledOpacity, child: text),
      ),
    );
  }
}
