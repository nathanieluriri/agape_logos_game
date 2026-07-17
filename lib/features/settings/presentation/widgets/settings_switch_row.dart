import 'package:flutter/widgets.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/pond_switch.dart';

/// A labeled toggle row inside a [SettingsSection]. The whole row is the tap
/// target; the pond switch swims to match. Label and switch merge into one
/// semantics node so screen readers hear the visible text plus the state.
class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.padLabel,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              PondSwitch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}
