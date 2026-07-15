// lib/features/multiplayer/presentation/widgets/multiplayer_sheet.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/glyphs/pond_glyph.dart';
import '../../../../shared/widgets/pond_action_button.dart';
import '../../../../shared/widgets/pond_sheet.dart';
import '../../application/resume_providers.dart';

/// What the player picked on the multiplayer chooser sheet.
enum MultiplayerChoice { create, join, resume }

/// Opens the multiplayer chooser as a pond bottom sheet. Resolves to the
/// picked action, or null when dismissed.
Future<MultiplayerChoice?> showMultiplayerSheet(BuildContext context) {
  return showPondSheet<MultiplayerChoice>(
    context: context,
    builder: (_) => const MultiplayerSheetContent(),
  );
}

/// Sheet body: a title and the match entry points. A ConsumerWidget so the
/// Resume entry can show a count badge for pending challenges + in-progress
/// games.
class MultiplayerSheetContent extends ConsumerWidget {
  const MultiplayerSheetContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenges = ref.watch(incomingChallengesProvider).value?.length ?? 0;
    final games = ref.watch(activeMatchesProvider).value?.length ?? 0;
    final resumeCount = challenges + games;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Play with friends',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.padLabel,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PondActionButton(
          glyph: PondGlyph.plus,
          label: 'Create a match',
          onPressed: () => Navigator.of(context).pop(MultiplayerChoice.create),
        ),
        const SizedBox(height: AppSpacing.md),
        PondActionButton(
          glyph: PondGlyph.key,
          label: 'Join with a code',
          onPressed: () => Navigator.of(context).pop(MultiplayerChoice.join),
        ),
        const SizedBox(height: AppSpacing.md),
        _ResumeRow(
          count: resumeCount,
          onPressed: () => Navigator.of(context).pop(MultiplayerChoice.resume),
        ),
      ],
    );
  }
}

/// The Resume entry with an optional count badge overlaid on its top-right.
class _ResumeRow extends StatelessWidget {
  const _ResumeRow({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final button = PondActionButton(
      glyph: PondGlyph.versus,
      label: count > 0 ? 'Resume games ($count)' : 'Resume games',
      onPressed: onPressed,
    );
    if (count == 0) return button;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        Positioned(
          top: -6,
          right: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: const BoxDecoration(
              color: AppColors.dangerFill,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.all(Radius.circular(999)),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: AppColors.dangerOnPond,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
