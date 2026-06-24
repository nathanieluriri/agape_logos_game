import 'package:flutter/material.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/spacing.dart';

/// A tappable labeled row (Sign out, Delete account, links). [danger] tints it
/// with the danger color for destructive actions.
class SettingsActionRow extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final Color color = danger ? AppColors.danger : AppColors.padLabel;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(icon, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
