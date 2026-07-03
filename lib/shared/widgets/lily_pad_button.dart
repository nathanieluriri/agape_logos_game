// lib/shared/widgets/lily_pad_button.dart
import 'package:flutter/widgets.dart';

import '../../core/design/motion/curves.dart';
import '../../core/design/tokens/durations.dart';
import '../../core/haptics/haptics.dart';
import 'lily_pad.dart';

enum IdleMotion { float, bob }

/// A tappable lily pad: the shared "navigating button" used for Play,
/// Withdraw, and Bonus. Idle float/bob plus a press scale-down; honors
/// reduced-motion (no idle drift when animations are disabled).
class LilyPadButton extends StatefulWidget {
  const LilyPadButton({
    super.key,
    required this.size,
    required this.palette,
    required this.content,
    required this.onPressed,
    this.shape = PadShape.notched,
    this.rotationDegrees = 0,
    this.idle = IdleMotion.float,
    this.shadow = true,
    this.semanticLabel,
  });

  final double size;
  final LilyPadPalette palette;
  final PadShape shape;
  final double rotationDegrees;
  final Widget content;
  final VoidCallback onPressed;
  final IdleMotion idle;
  final bool shadow;
  final String? semanticLabel;

  @override
  State<LilyPadButton> createState() => _LilyPadButtonState();
}

class _LilyPadButtonState extends State<LilyPadButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: AppDurations.slow * 2,
  );
  bool _pressed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _idle.stop();
      _idle.value = 0;
    } else if (!_idle.isAnimating) {
      _idle.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final travel = widget.idle == IdleMotion.float ? 7.0 : 5.0;
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
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1.0,
          duration: AppDurations.instant,
          curve: AppCurves.emphasized,
          child: AnimatedBuilder(
            animation: _idle,
            builder: (context, child) {
              final dy = -travel * AppCurves.float.transform(_idle.value);
              return Transform.translate(offset: Offset(0, dy), child: child);
            },
            child: LilyPad(
              size: widget.size,
              palette: widget.palette,
              shape: widget.shape,
              rotationDegrees: widget.rotationDegrees,
              shadow: widget.shadow,
              child: ExcludeSemantics(child: widget.content),
            ),
          ),
        ),
      ),
    );
  }
}
