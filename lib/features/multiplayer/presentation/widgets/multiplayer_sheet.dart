// lib/features/multiplayer/presentation/widgets/multiplayer_sheet.dart
import 'package:flutter/widgets.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/glyphs/pond_glyph.dart';
import '../../../../shared/widgets/pond_action_button.dart';
import '../../../../shared/widgets/pond_sheet.dart';

/// What the player picked on the multiplayer chooser sheet.
enum MultiplayerChoice { create, join }

/// Opens the multiplayer chooser as a pond bottom sheet. Resolves to the
/// picked action, or null when dismissed.
Future<MultiplayerChoice?> showMultiplayerSheet(BuildContext context) {
  return showPondSheet<MultiplayerChoice>(
    context: context,
    builder: (_) => const MultiplayerSheetContent(),
  );
}

/// Sheet body: a title and the two match entry points.
class MultiplayerSheetContent extends StatelessWidget {
  const MultiplayerSheetContent({super.key});

  @override
  Widget build(BuildContext context) {
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
          onPressed: () =>
              Navigator.of(context).pop(MultiplayerChoice.create),
        ),
        const SizedBox(height: AppSpacing.md),
        PondActionButton(
          glyph: PondGlyph.key,
          label: 'Join with a code',
          onPressed: () => Navigator.of(context).pop(MultiplayerChoice.join),
        ),
      ],
    );
  }
}
