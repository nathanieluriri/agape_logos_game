import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/pond_background.dart';
import '../../../../shared/widgets/pond_page_header.dart';
import '../../../../shared/widgets/pond_stage.dart';
import '../../application/social_providers.dart';
import '../widgets/match_history_row.dart';

/// The caller's game history. Thin composition over `matchHistoryProvider`.
class MatchHistoryPage extends ConsumerWidget {
  const MatchHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(matchHistoryProvider);
    return Scaffold(
      backgroundColor: AppColors.transparent,
      body: PondBackground(
        child: PondStage(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PondPageHeader(title: 'Match History'),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: history.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) =>
                      const _Message('Could not load your history.'),
                  data: (entries) => entries.isEmpty
                      ? const _Message(
                          'No matches yet. Play a multiplayer game!',
                        )
                      : RefreshIndicator(
                          onRefresh: () async =>
                              ref.invalidate(matchHistoryProvider),
                          child: ListView.builder(
                            itemCount: entries.length,
                            itemBuilder: (context, i) =>
                                MatchHistoryRow(entry: entries[i]),
                          ),
                        ),
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
        style: const TextStyle(color: AppColors.padLabelSoft, fontSize: 14),
      ),
    ),
  );
}
