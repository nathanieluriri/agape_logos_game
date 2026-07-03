import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/pond_background.dart';
import '../../../../shared/widgets/pond_loader.dart';
import '../../../../shared/widgets/pond_pill_button.dart';
import '../../../../shared/widgets/pond_stage.dart';
import '../../application/auth_providers.dart';
import '../../domain/auth_user.dart';
import '../widgets/auth_page_header.dart';

/// Profile surface on the pond: shows the signed-in user or a prompt to sign
/// in. Reachable from the home screen; never required for play.
class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return Scaffold(
      body: PondBackground(
        child: PondStage(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthPageHeader(title: 'Account'),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: auth.when(
                  loading: () => const Center(
                    child: PondLoader(label: 'Loading account'),
                  ),
                  error: (_, __) => const Text(
                    'Could not load account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.padLabelSoft),
                  ),
                  data: (user) =>
                      user == null ? const _SignedOut() : _SignedIn(user: user),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignedOut extends StatelessWidget {
  const _SignedOut();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Sign in to sync your progress',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.padLabel,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        PondPillButton(
          label: 'Sign in',
          onPressed: () => context.push('/sign-in'),
        ),
      ],
    );
  }
}

class _SignedIn extends ConsumerWidget {
  const _SignedIn({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          user.displayName ?? user.email ?? 'Signed in',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.padLabel,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        PondPillButton(
          label: 'Sign out',
          variant: PondPillVariant.quiet,
          onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
        ),
      ],
    );
  }
}
