import 'package:flutter/material.dart';

import '../../../../core/design/motion/curves.dart';
import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/durations.dart';
import '../../../../core/design/tokens/spacing.dart';

/// A tappable labeled row (Sign out, Delete account, links) with a round
/// glyph chip and a gentle press scale instead of an ink ripple. [danger]
/// tints it with the on-pond danger color for destructive actions.
class SettingsActionRow extends StatefulWidget {
  const SettingsActionRow({
    super.key,
    required this.label,
    required this.onTap,
    this.danger = false,
    this.icon = Icons.chevron_right,
  });

  final String label;
  final VoidCallback onTap;
  final bool danger;
  final IconData icon;

  @override
  State<SettingsActionRow> createState() => _SettingsActionRowState();
}

class _SettingsActionRowState extends State<SettingsActionRow> {
  /// Diameter of the trailing glyph chip.
  static const double _chipSize = 26;

  /// Glyph size inside the chip.
  static const double _glyphSize = 16;

  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color color = widget.danger
        ? AppColors.dangerOnPond
        : AppColors.padLabel;
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {
          setState(() => _pressed = false);
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1.0,
          duration: AppDurations.instant,
          curve: AppCurves.emphasized,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + AppSpacing.xs,
            ),
            child: ExcludeSemantics(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    width: _chipSize,
                    height: _chipSize,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.settingsHalo,
                    ),
                    child: Icon(widget.icon, size: _glyphSize, color: color),
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
