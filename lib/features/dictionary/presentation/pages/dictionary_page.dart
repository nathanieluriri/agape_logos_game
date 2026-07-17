import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/pond_background.dart';
import '../../../../shared/widgets/pond_loader.dart';
import '../../../../shared/widgets/pond_page_header.dart';
import '../../../../shared/widgets/pond_pill_button.dart';
import '../../../auth/application/auth_providers.dart';
import '../../application/dictionary_providers.dart';
import '../widgets/dictionary_list.dart';

/// The all-levels dictionary: every word the player has solved so far, from the
/// backend (survives reinstall, cross-device), cached in Drift and served
/// offline. A full-height searchable list, so it does NOT use PondStage (which
/// scroll-wraps its child); it lays out its own scrollable list under the header.
class DictionaryPage extends ConsumerWidget {
  const DictionaryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      backgroundColor: AppColors.transparent,
      body: PondBackground(
        child: SafeArea(
          child: Column(
            children: [
              const PondPageHeader(title: 'Dictionary'),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: user == null
                    ? const _SignedOutNotice()
                    : const _DictionaryBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DictionaryBody extends ConsumerWidget {
  const _DictionaryBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kick the network fetch (write-through); watch it only for the first-load
    // spinner / error while the cache is still empty.
    final refresh = ref.watch(dictionaryRefreshProvider);
    final entries = ref.watch(dictionaryEntriesProvider).value ?? const [];

    if (entries.isEmpty) {
      if (refresh.isLoading) {
        return const Center(
          child: PondLoader(label: 'Opening your dictionary'),
        );
      }
      if (refresh.hasError) {
        return _DictionaryError(
          onRetry: () => ref.invalidate(dictionaryRefreshProvider),
        );
      }
      return const _EmptyNotice();
    }
    return DictionaryList(entries: entries);
  }
}

class _SignedOutNotice extends StatelessWidget {
  const _SignedOutNotice();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Sign in to see the words you have collected.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.padLabelSoft, fontSize: 15),
          ),
          const SizedBox(height: AppSpacing.lg),
          PondPillButton(
            label: 'Sign in',
            onPressed: () => context.push('/sign-in'),
          ),
        ],
      ),
    );
  }
}

class _EmptyNotice extends StatelessWidget {
  const _EmptyNotice();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: Text(
          'Your dictionary is empty for now. Solve levels to collect words and '
          'their meanings here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.padLabelSoft, fontSize: 15),
        ),
      ),
    );
  }
}

class _DictionaryError extends StatelessWidget {
  const _DictionaryError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Could not load your dictionary. Check your connection.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.padLabelSoft, fontSize: 15),
          ),
          const SizedBox(height: AppSpacing.lg),
          PondPillButton(label: 'Retry', onPressed: onRetry),
        ],
      ),
    );
  }
}
