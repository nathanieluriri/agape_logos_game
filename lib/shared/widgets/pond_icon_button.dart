// lib/shared/widgets/pond_icon_button.dart
import 'package:flutter/widgets.dart';

import '../../core/design/motion/curves.dart';
import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/durations.dart';
import '../../core/design/tokens/gradients.dart';
import '../../core/design/tokens/shadows.dart';
import '../../core/design/tokens/sizing.dart';
import '../../core/haptics/haptics.dart';

/// Round pond icon button: a soft translucent halo ring around a gradient
/// teal disc with a cream icon. The generic sibling of the settings gear,
/// for any icon action that sits on the water chrome. Scales down on press.
class PondIconButton extends StatefulWidget {
  const PondIconButton({
    super.key,
    required this.glyph,
    required this.onPressed,
    this.semanticLabel,
    this.size = AppSizing.topBarButton,
  });

  /// The glyph shown on the disc, already sized by the caller (a [PondIcon]
  /// or, transitionally, an [Icon]).
  final Widget glyph;

  /// Called when the button is tapped.
  final VoidCallback onPressed;

  /// Accessibility label describing the action.
  final String? semanticLabel;

  /// Outer diameter, halo ring included.
  final double size;

  @override
  State<PondIconButton> createState() => _PondIconButtonState();
}

class _PondIconButtonState extends State<PondIconButton> {
  /// Halo ring thickness around the inner disc (matches the settings gear).
  static const double _haloPadding = 5;

  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
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
          scale: _pressed ? 0.93 : 1.0,
          duration: AppDurations.instant,
          curve: AppCurves.emphasized,
          child: Container(
            width: widget.size,
            height: widget.size,
            padding: const EdgeInsets.all(_haloPadding),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.settingsHalo,
            ),
            child: Container(
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.settingsInner,
                boxShadow: AppShadows.pill,
              ),
              child: ExcludeSemantics(child: widget.glyph),
            ),
          ),
        ),
      ),
    );
  }
}
