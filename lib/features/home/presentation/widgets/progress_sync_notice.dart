import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/pond_pill_button.dart';
import '../../../profile/application/progress_sync_providers.dart';

/// A quiet banner shown ONLY when a completed level failed to reach the cloud.
/// Normal offline play syncs invisibly and shows nothing. Tapping Retry re-arms
/// the failed mutations and flushes.
class ProgressSyncNotice extends ConsumerWidget {
  const ProgressSyncNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failed = ref.watch(progressSyncFailedProvider).value ?? false;
    if (!failed) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.progressTrack,
        // PLAN: AppRadii.card is already a BorderRadius token, so it is used
        // directly (the plan snippet wrapped it in BorderRadius.circular).
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.progressTrackBorder),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Some progress did not save',
                  style: TextStyle(
                    color: AppColors.wordmark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  'We could not reach the cloud. Your levels are safe here.',
                  style: TextStyle(color: AppColors.padLabelSoft, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          PondPillButton(
            label: 'Retry',
            onPressed: () => retryFailedProgress(ref),
          ),
        ],
      ),
    );
  }
}
