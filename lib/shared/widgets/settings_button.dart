// lib/shared/widgets/settings_button.dart
import 'package:flutter/material.dart';

import '../../core/design/tokens/colors.dart';
import '../../core/design/tokens/durations.dart';
import '../../core/design/tokens/gradients.dart';
import '../../core/design/tokens/shadows.dart';
import '../../core/design/tokens/sizing.dart';
import '../../core/haptics/haptics.dart';

/// Round settings gear: a soft translucent halo ring around a gradient teal
/// disc with a filled cream gear. Scales down slightly on press.
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
          Haptics.instance.lightImpact();
          widget.onPressed();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.93 : 1.0,
          duration: AppDurations.instant,
          child: Container(
            width: AppSizing.settingsButton,
            height: AppSizing.settingsButton,
            padding: const EdgeInsets.all(5),
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
              child: const ExcludeSemantics(
                child: Icon(Icons.settings, color: AppColors.wordmark, size: 22),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
