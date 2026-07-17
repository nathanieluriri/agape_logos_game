// lib/shared/widgets/lily_pad_button.dart
import 'package:flutter/widgets.dart';

import '../../core/design/motion/curves.dart';
import '../../core/design/tokens/durations.dart';
import '../../core/haptics/haptics.dart';
import 'float_motion.dart';
import 'lily_pad.dart';

/// A tappable lily pad: the shared "navigating button" used for Play, Withdraw,
/// and Bonus. Idle premium float (bob + scale breath + gentle tilt, with the
/// cast shadow coupled to the bob) via [FloatMotion], plus a press scale-down.
/// Honours reduced motion (static at rest when animations are disabled).
class LilyPadButton extends StatefulWidget {
  const LilyPadButton({
    super.key,
    required this.size,
    required this.palette,
    required this.content,
    required this.onPressed,
    this.shape = PadShape.notched,
    this.rotationDegrees = 0,
    this.phase = 0,
    this.shadow = true,
    this.semanticLabel,
  });

  final double size;
  final LilyPadPalette palette;
  final PadShape shape;
  final double rotationDegrees;
  final Widget content;
  final VoidCallback onPressed;

  /// Bob phase (fraction of a cycle, 0..1) so several pads on one screen float
  /// out of sync. See [FloatMotion.phase].
  final double phase;
  final bool shadow;
  final String? semanticLabel;

  @override
  State<LilyPadButton> createState() => _LilyPadButtonState();
}

class _LilyPadButtonState extends State<LilyPadButton> {
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
          Haptics.instance.mediumImpact();
          widget.onPressed();
        },
        // PLAN: the press scale 0.92 is the pre-existing value (unchanged
        // behaviour); left as-is to avoid scope creep. FloatMotion sits INSIDE
        // the press AnimatedScale, so pressing squashes the whole floating pad
        // (bob + press compose), which is the intended feel.
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1.0,
          duration: AppDurations.instant,
          curve: AppCurves.emphasized,
          child: FloatMotion(
            phase: widget.phase,
            builder: (context, lift, child) => LilyPad(
              size: widget.size,
              palette: widget.palette,
              shape: widget.shape,
              rotationDegrees: widget.rotationDegrees,
              shadow: widget.shadow,
              lift: lift,
              child: child,
            ),
            child: ExcludeSemantics(child: widget.content),
          ),
        ),
      ),
    );
  }
}
