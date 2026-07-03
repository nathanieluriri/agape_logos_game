// lib/features/game/presentation/widgets/dictionary_sheet.dart
import 'package:flutter/material.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/gradients.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/lily_pad.dart';
import '../../../puzzles/domain/puzzle.dart';

/// Opens the in-game dictionary: a pond bottom sheet listing the current
/// puzzle's words. Found words surface with their definitions; unfound words
/// stay masked (hint-revealed leading letters excepted).
Future<void> showDictionarySheet(
  BuildContext context, {
  required List<PuzzleAnswer> targets,
  required Set<String> found,
  required Map<String, int> revealed,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.transparent,
    elevation: 0,
    showDragHandle: false,
    barrierColor: AppColors.pondScrim,
    isScrollControlled: true,
    builder: (_) => DictionarySheetContent(
      targets: targets,
      found: found,
      revealed: revealed,
    ),
  );
}

/// Body of the dictionary sheet: a deep-water card with one entry per target
/// word, in puzzle order. Provider-free so tests and previews can pump it
/// directly. [found] and [revealed] are keyed by UPPERCASE word, matching the
/// game session.
class DictionarySheetContent extends StatelessWidget {
  const DictionarySheetContent({
    super.key,
    required this.targets,
    required this.found,
    required this.revealed,
  });

  final List<PuzzleAnswer> targets;
  final Set<String> found;
  final Map<String, int> revealed;

  /// Hand-rolled drag bar dimensions (matches the other pond sheets).
  static const double _dragBarWidth = 40;
  static const double _dragBarHeight = 4;

  /// Diameter of the decorative pad above the title.
  static const double _padSize = 44;

  /// The whole sheet (header included) never grows past this fraction of the
  /// screen; beyond it, the word list scrolls inside the sheet. Bounding the
  /// full sheet keeps short viewports (web landscape, split screen) from
  /// overflowing the header.
  static const double _maxSheetHeightFraction = 0.85;

  static const _sheetDecoration = BoxDecoration(
    gradient: AppGradients.pondCard,
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(AppRadii.lg),
      topRight: Radius.circular(AppRadii.lg),
    ),
    border: Border(top: BorderSide(color: AppColors.settingsBorder)),
  );

  static const _dragBarDecoration = BoxDecoration(
    color: AppColors.settingsBorder,
    borderRadius: BorderRadius.all(Radius.circular(AppRadii.sm)),
  );

  /// Hairline separator between entries (mirrors the settings card rows).
  static const _divider = Padding(
    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
    child: SizedBox(
      height: 1,
      child: ColoredBox(color: AppColors.rowDivider),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final maxSheetHeight =
        MediaQuery.sizeOf(context).height * _maxSheetHeightFraction;
    return DecoratedBox(
      decoration: _sheetDecoration,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxSheetHeight),
          child: Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.lg,
              bottom: AppSpacing.md,
            ),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: SizedBox(
                  width: _dragBarWidth,
                  height: _dragBarHeight,
                  child: DecoratedBox(decoration: _dragBarDecoration),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Center(
                child: LilyPad(
                  size: _padSize,
                  palette: LilyPadPalette.teal,
                  shape: PadShape.smooth,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Dictionary',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.padLabel,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Words from this pond.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.padLabelSoft, fontSize: 14),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Flexible: hugs short lists, shrinks and scrolls long ones
              // within the sheet's overall height bound.
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: targets.length,
                  separatorBuilder: (_, __) => _divider,
                  itemBuilder: (_, index) {
                    final answer = targets[index];
                    final key = answer.word.toUpperCase();
                    return _DictionaryEntry(
                      answer: answer,
                      isFound: found.contains(key),
                      revealedCount: revealed[key] ?? 0,
                    );
                  },
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One word row: the solved word with its definition, or a masked slot line
/// for words still hidden in the pond.
class _DictionaryEntry extends StatelessWidget {
  const _DictionaryEntry({
    required this.answer,
    required this.isFound,
    required this.revealedCount,
  });

  final PuzzleAnswer answer;
  final bool isFound;
  final int revealedCount;

  static const _wordStyle = TextStyle(
    color: AppColors.padLabel,
    fontSize: 16,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.5,
  );

  /// Base style of the masked slot line; visible letters brighten to
  /// [AppColors.padLabel] via a child span.
  static const _maskStyle = TextStyle(
    color: AppColors.padLabelSoft,
    fontSize: 16,
    fontWeight: FontWeight.w800,
    letterSpacing: 2,
  );

  static const _definitionStyle = TextStyle(
    color: AppColors.padLabelSoft,
    fontSize: 14,
    height: 1.35,
  );

  static const _hiddenHintStyle = TextStyle(
    color: AppColors.padLabelSoft,
    fontSize: 13,
  );

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + AppSpacing.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: isFound ? _foundChildren() : _hiddenChildren(),
        ),
      ),
    );
  }

  List<Widget> _foundChildren() => [
        Text(answer.word.toUpperCase(), style: _wordStyle),
        const SizedBox(height: AppSpacing.xs),
        Text(
          answer.definition ?? 'No definition for this one yet.',
          style: _definitionStyle,
        ),
      ];

  List<Widget> _hiddenChildren() {
    final word = answer.word.toUpperCase();
    // First `revealedCount` letters visible (capped defensively at both
    // ends), the rest '_' slots joined by spaces: 'P _ _ _' for one revealed
    // letter of POND.
    final shown = revealedCount < 0
        ? 0
        : (revealedCount > word.length ? word.length : revealedCount);
    final visible = word.substring(0, shown).split('').join(' ');
    final mask = List.filled(word.length - shown, '_').join(' ');
    return [
      Text.rich(
        TextSpan(
          style: _maskStyle,
          children: [
            if (visible.isNotEmpty)
              TextSpan(
                text: mask.isEmpty ? visible : '$visible ',
                style: const TextStyle(color: AppColors.padLabel),
              ),
            if (mask.isNotEmpty) TextSpan(text: mask),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      const Text('Still hidden in the pond.', style: _hiddenHintStyle),
    ];
  }
}
