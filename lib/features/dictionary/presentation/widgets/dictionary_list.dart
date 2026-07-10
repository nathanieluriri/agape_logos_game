import 'package:flutter/material.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../domain/dictionary_entry.dart';

/// Searchable, tier-grouped list of solved words. Provider-free so it can be
/// pumped directly in tests and previews. Reuses the visual language of the
/// in-game dictionary sheet (bold caps word, soft definition beneath).
class DictionaryList extends StatefulWidget {
  const DictionaryList({super.key, required this.entries});

  final List<DictionaryEntry> entries;

  @override
  State<DictionaryList> createState() => _DictionaryListState();
}

class _DictionaryListState extends State<DictionaryList> {
  String _query = '';

  /// Display order + labels for the tier sections.
  static const List<String> _tierOrder = ['easy', 'medium', 'hard', 'expert'];
  static const Map<String, String> _tierLabels = {
    'easy': 'Easy',
    'medium': 'Medium',
    'hard': 'Hard',
    'expert': 'Expert',
  };

  List<DictionaryEntry> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.entries;
    return widget.entries
        .where((e) =>
            e.word.toLowerCase().contains(q) ||
            (e.definition?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final entries = _filtered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: _SearchField(
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (entries.isEmpty)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Text(
              'No words match your search.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.padLabelSoft, fontSize: 15),
            ),
          )
        else
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              children: [
                for (final tier in _tierOrder)
                  ..._section(
                    tier,
                    entries.where((e) => e.tier == tier).toList()
                      ..sort((a, b) => a.word.compareTo(b.word)),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  List<Widget> _section(String tier, List<DictionaryEntry> group) {
    if (group.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xs,
        ),
        child: Text(
          _tierLabels[tier] ?? tier,
          style: const TextStyle(
            color: AppColors.padLabelSoft,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      for (final e in group) _WordTile(entry: e),
    ];
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.padLabel),
      cursorColor: AppColors.padLabel,
      decoration: const InputDecoration(
        hintText: 'Search words',
        hintStyle: TextStyle(color: AppColors.padLabelSoft),
        prefixIcon: Icon(Icons.search, color: AppColors.padLabelSoft),
        filled: true,
        fillColor: AppColors.progressTrack,
        contentPadding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        border: OutlineInputBorder(
          borderRadius: AppRadii.card,
          borderSide: BorderSide(color: AppColors.progressTrackBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.card,
          borderSide: BorderSide(color: AppColors.progressTrackBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.card,
          borderSide: BorderSide(color: AppColors.settingsBorder),
        ),
      ),
    );
  }
}

/// One word row: the solved word in bold caps with its definition beneath.
class _WordTile extends StatelessWidget {
  const _WordTile({required this.entry});

  final DictionaryEntry entry;

  static const _wordStyle = TextStyle(
    color: AppColors.padLabel,
    fontSize: 16,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.5,
  );
  static const _definitionStyle = TextStyle(
    color: AppColors.padLabelSoft,
    fontSize: 14,
    height: 1.35,
  );

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.word.toUpperCase(), style: _wordStyle),
            const SizedBox(height: AppSpacing.xs),
            Text(
              entry.definition ?? 'No definition for this one yet.',
              style: _definitionStyle,
            ),
          ],
        ),
      ),
    );
  }
}
