import 'package:flutter/material.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/pond_pill_button.dart';
import '../../domain/friend_request.dart';
import 'social_avatar_dot.dart';

/// One incoming request: avatar, name/@handle, Accept + Decline pills. The pills
/// are disabled (dimmed) while [busy] so a double-tap cannot double-respond.
class FriendRequestTile extends StatelessWidget {
  const FriendRequestTile({
    super.key,
    required this.request,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
  });

  final FriendRequest request;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        children: [
          // Row 1: avatar + name/handle
          Row(
            children: [
              SocialAvatarDot(name: request.displayName),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.padLabel,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '@${request.handle}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.padLabelSoft,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Row 2: right-aligned buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PondPillButton(
                label: 'Accept',
                enabled: !busy,
                semanticLabel: 'Accept ${request.displayName}',
                onPressed: onAccept,
              ),
              const SizedBox(width: AppSpacing.md),
              PondPillButton(
                label: 'Decline',
                variant: PondPillVariant.quiet,
                enabled: !busy,
                semanticLabel: 'Decline ${request.displayName}',
                onPressed: onDecline,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
