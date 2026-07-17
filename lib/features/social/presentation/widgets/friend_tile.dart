import 'package:flutter/material.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/versus_mark.dart';
import '../../domain/friend.dart';
import 'social_avatar_dot.dart';

/// One accepted friend: avatar, display name, @handle. Tapping opens the
/// friend's public profile; the trailing versus glyph sends a challenge.
class FriendTile extends StatelessWidget {
  const FriendTile({
    super.key,
    required this.friend,
    required this.onTap,
    required this.onChallenge,
  });

  final Friend friend;
  final VoidCallback onTap;
  final VoidCallback onChallenge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            SocialAvatarDot(name: friend.displayName),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.displayName,
                    style: const TextStyle(
                      color: AppColors.padLabel,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '@${friend.handle}',
                    style: const TextStyle(
                      color: AppColors.padLabelSoft,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Semantics(
              button: true,
              label: 'Challenge ${friend.displayName}',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onChallenge,
                child: const Padding(
                  padding: EdgeInsets.all(AppSpacing.xs),
                  child: VersusMark(size: 22),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.chevron_right, color: AppColors.padLabelSoft),
          ],
        ),
      ),
    );
  }
}
