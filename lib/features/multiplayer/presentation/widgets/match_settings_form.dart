import 'package:flutter/material.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/pond_pill_button.dart';
import '../../domain/match_settings.dart';
import '../../domain/multiplayer_config.dart';

/// Creator-only match settings: difficulty, base time, and (gated) a theme
/// picker. Emits the chosen [MatchSettings] via [onCreate].
class MatchSettingsForm extends StatefulWidget {
  const MatchSettingsForm({super.key, required this.onCreate, this.busy = false});

  final void Function(MatchSettings settings) onCreate;
  final bool busy;

  @override
  State<MatchSettingsForm> createState() => _MatchSettingsFormState();
}

class _MatchSettingsFormState extends State<MatchSettingsForm> {
  MatchDifficulty _difficulty = MatchDifficulty.medium;
  int _durationSec = 120;

  static const _durations = <int>[60, 120, 180];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Difficulty'),
        const SizedBox(height: AppSpacing.sm),
        _ChoiceRow<MatchDifficulty>(
          values: MatchDifficulty.values,
          selected: _difficulty,
          labelOf: (d) => d.name[0].toUpperCase() + d.name.substring(1),
          onSelected: (d) => setState(() => _difficulty = d),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _FieldLabel('Round time'),
        const SizedBox(height: AppSpacing.sm),
        _ChoiceRow<int>(
          values: _durations,
          selected: _durationSec,
          labelOf: (s) => '${s ~/ 60}:00',
          onSelected: (s) => setState(() => _durationSec = s),
        ),
        if (kThemeSystemEnabled) ...[
          const SizedBox(height: AppSpacing.lg),
          const _FieldLabel('Theme'),
          const SizedBox(height: AppSpacing.sm),
          // PLAN: when the theme system is live (plan 11), replace this with a
          // searchable theme picker backed by GET /themes?q= and set
          // settings.theme to the chosen id. Hidden entirely while gated.
          const Text(
            'Themed matches coming soon',
            style: TextStyle(color: AppColors.padLabelSoft, fontSize: 13),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: PondPillButton(
            label: widget.busy ? 'Creating...' : 'Create match',
            // PondPillButton.onPressed is non-nullable; `enabled` gates taps.
            enabled: !widget.busy,
            onPressed: () => widget.onCreate(
              MatchSettings(
                difficulty: _difficulty,
                durationSec: _durationSec,
                rackSize: 7,
                theme: null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: AppColors.wordmark,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      );
}

class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });
  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final void Function(T) onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        for (final v in values)
          _ChoiceChip(
            label: labelOf(v),
            selected: v == selected,
            onTap: () => onSelected(v),
          ),
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.plusButtonDeep : AppColors.pillFill,
            borderRadius: AppRadii.pill,
            border: Border.all(
              color: selected ? AppColors.plusButtonBorder : AppColors.pillBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.padLabel : AppColors.pillText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
