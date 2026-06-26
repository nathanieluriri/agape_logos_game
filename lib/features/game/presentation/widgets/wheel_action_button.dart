import 'package:flutter/material.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/durations.dart';
import '../../../../core/design/motion/curves.dart';

/// A circular Shuffle/Hint button with an optional count badge.
class WheelActionButton extends StatefulWidget {
  const WheelActionButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    this.badge,
    this.enabled = true,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;
  final int? badge;
  final bool enabled;

  @override
  State<WheelActionButton> createState() => _WheelActionButtonState();
}

class _WheelActionButtonState extends State<WheelActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      onTap: widget.enabled ? widget.onTap : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.enabled
            ? () {
                setState(() => _pressed = false);
                widget.onTap();
              }
            : null,
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1.0,
          duration: AppDurations.instant,
          curve: AppCurves.emphasized,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.pillFill,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.pillBorder),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.enabled ? AppColors.pillText : AppColors.slotEmpty,
                ),
              ),
              if (widget.badge != null && widget.badge! > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${widget.badge}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.tileBlueText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
