import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/pond_background.dart';
import '../../../../shared/widgets/pond_page_header.dart';
import '../../../../shared/widgets/pond_stage.dart';
import '../../application/social_providers.dart';
import '../../data/social_remote.dart';
import '../../domain/public_profile_detail.dart';
import '../widgets/match_history_row.dart';
import '../widgets/social_avatar_dot.dart';

/// A read-only view of another player's public profile and recent matches.
/// Shows a private state when the target is not visible to the caller.
class PublicProfilePage extends ConsumerWidget {
  const PublicProfilePage({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(publicProfileProvider(uid));
    return Scaffold(
      body: PondBackground(
        // This page owns its scrolling (a ListView of match history), so the
        // stage must not wrap it in SingleChildScrollView + IntrinsicHeight.
        child: PondStage.fill(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PondPageHeader(title: 'Profile'),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: detail.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, __) => _Message(
                    e is ProfileNotVisible
                        ? 'This profile is private.'
                        : 'Could not load this profile.',
                  ),
                  data: (d) => _Body(detail: d),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.detail});

  final PublicProfileDetail detail;

  @override
  Widget build(BuildContext context) {
    final p = detail.profile;
    return ListView(
      children: [
        Column(
          children: [
            SocialAvatarDot(name: p.displayName, size: 72),
            const SizedBox(height: AppSpacing.md),
            Text(
              p.displayName,
              style: const TextStyle(
                color: AppColors.padLabel,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              // PLAN: reflect guest status per the multiplayer contract (guests
              // can be lost on reinstall). A guest shows a note beside the handle.
              p.isGuest ? '@${p.handle} - guest' : '@${p.handle}',
              style: const TextStyle(color: AppColors.padLabelSoft, fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Level ${p.highestLevel + 1}  -  ${p.totalScore} pts',
              style: const TextStyle(color: AppColors.padLabelSoft, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        if (detail.recentMatches.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
            child: Text(
              'RECENT MATCHES',
              style: TextStyle(
                color: AppColors.padLabel,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          for (final m in detail.recentMatches) MatchHistoryRow(entry: m),
        ],
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.padLabelSoft, fontSize: 15),
          ),
        ),
      );
}
