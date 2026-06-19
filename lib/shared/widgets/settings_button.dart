// lib/shared/widgets/settings_button.dart
import 'package:flutter/material.dart';

import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/durations.dart';
import '../../core/design/tokens/sizing.dart';

/// Round translucent settings gear; scales down slightly on press.
class SettingsButton extends StatefulWidget {
  const SettingsButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<SettingsButton> createState() => _SettingsButtonState();
}

class _SettingsButtonState extends State<SettingsButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Settings',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {
          setState(() => _pressed = false);
          widget.onPressed();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.93 : 1.0,
          duration: AppDurations.instant,
          child: Container(
            width: AppSizing.settingsButton,
            height: AppSizing.settingsButton,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.settingsFill,
              border: Border.all(color: AppColors.settingsBorder, width: 2.5),
            ),
            child: const ExcludeSemantics(
              child: Icon(Icons.settings, color: AppColors.wordmark, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}
