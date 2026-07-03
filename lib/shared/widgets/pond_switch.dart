// lib/shared/widgets/pond_switch.dart
import 'package:flutter/widgets.dart';

import '../../core/design/motion/curves.dart';
import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/durations.dart';
import '../../core/design/tokens/radii.dart';
import '../../core/design/tokens/shadows.dart';
import '../../core/design/tokens/sizing.dart';
import '../../core/design/tokens/spacing.dart';
import '../../core/haptics/haptics.dart';
import 'lily_pad.dart';

/// Pond toggle: a translucent water track with a mini lily pad that swims
/// from bank to bank, tilting playfully as it crosses. The app-wide stand-in
/// for the Material Switch.
class PondSwitch extends StatefulWidget {
  const PondSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  /// Whether the switch is on.
  final bool value;

  /// Called with the toggled value when the switch is tapped.
  final ValueChanged<bool> onChanged;

  /// Accessibility label describing what the switch controls.
  final String? semanticLabel;

  @override
  State<PondSwitch> createState() => _PondSwitchState();
}

class _PondSwitchState extends State<PondSwitch> {
  /// Playful knob tilt, in turns (about 14 degrees).
  static const double _knobTilt = 0.04;

  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final on = widget.value;
    return Semantics(
      button: true,
      enabled: true,
      toggled: on,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {
          setState(() => _pressed = false);
          Haptics.instance.selectionClick();
          widget.onChanged(!on);
        },
        // Transparent vertical hit padding lifts the tap target to 48+
        // without changing the visual size of the track.
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: AnimatedScale(
            scale: _pressed ? 0.94 : 1.0,
            duration: AppDurations.instant,
            curve: AppCurves.emphasized,
            child: AnimatedContainer(
              duration: AppDurations.normal,
              curve: AppCurves.emphasized,
              width: AppSizing.switchTrackWidth,
              height: AppSizing.switchTrackHeight,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: on ? AppColors.switchTrackOn : AppColors.pillFill,
                borderRadius: AppRadii.pill,
                border: Border.all(
                  color: on ? AppColors.settingsBorder : AppColors.pillBorder,
                ),
                boxShadow: AppShadows.pill,
              ),
              child: AnimatedAlign(
                alignment: on ? Alignment.centerRight : Alignment.centerLeft,
                duration: AppDurations.normal,
                curve: AppCurves.emphasized,
                child: AnimatedRotation(
                  turns: on ? _knobTilt : -_knobTilt,
                  duration: AppDurations.normal,
                  curve: AppCurves.emphasized,
                  child: LilyPad(
                    size: AppSizing.switchKnob,
                    palette: on ? LilyPadPalette.green : LilyPadPalette.teal,
                    shape: PadShape.smooth,
                    shadow: false,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
