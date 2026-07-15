// lib/features/multiplayer/presentation/widgets/challenge_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/glyphs/pond_glyph.dart';
import '../../../../shared/widgets/pond_action_button.dart';
import '../../../../shared/widgets/pond_sheet.dart';
import '../../../social/domain/friend.dart';
import '../../application/match_providers.dart';
import '../../domain/challenge_outcome.dart';

/// Opens the challenge chooser (Play now / 6-hour game) for [friend] as a
/// pond bottom sheet. Sends the challenge and reports the outcome via a
/// SnackBar; never navigates the challenger into the match (they wait for
/// the friend to accept).
Future<void> showChallengeSheet(BuildContext context, Friend friend) {
  return showPondSheet<void>(
    context: context,
    builder: (_) => ChallengeSheetContent(friend: friend),
  );
}

/// Sheet body: a title naming the friend and the two challenge modes.
class ChallengeSheetContent extends ConsumerStatefulWidget {
  const ChallengeSheetContent({super.key, required this.friend});

  final Friend friend;

  @override
  ConsumerState<ChallengeSheetContent> createState() =>
      _ChallengeSheetContentState();
}

class _ChallengeSheetContentState
    extends ConsumerState<ChallengeSheetContent> {
  bool _busy = false;

  Future<void> _send(String mode) async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final outcome = await ref
        .read(matchServiceProvider)
        .challenge(widget.friend.uid, mode: mode);
    if (!mounted) return;
    setState(() => _busy = false);
    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text(_messageFor(outcome))));
  }

  String _messageFor(ChallengeOutcome outcome) => switch (outcome) {
    ChallengeSent() => 'Challenge sent to ${widget.friend.displayName}',
    ChallengeAlreadyOpen() =>
      'You already have a game going with ${widget.friend.displayName}.',
    ChallengeNotFriends() => 'You can only challenge friends.',
    ChallengeUnavailable() => 'Could not reach the pond. Try again.',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Challenge ${widget.friend.displayName}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.padLabel,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PondActionButton(
          glyph: PondGlyph.versus,
          label: 'Play now',
          onPressed: () => _send('live'),
        ),
        const SizedBox(height: AppSpacing.md),
        PondActionButton(
          glyph: PondGlyph.book,
          label: '6-hour game',
          onPressed: () => _send('async'),
        ),
      ],
    );
  }
}
