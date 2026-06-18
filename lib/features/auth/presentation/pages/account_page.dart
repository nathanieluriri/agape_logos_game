import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/spacing.dart';
import '../../application/auth_providers.dart';
import '../../domain/auth_user.dart';

/// Profile surface: shows the signed-in user or a prompt to sign in. Reachable
/// from the home screen; never required for play.
class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: auth.when(
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Text('Could not load account.'),
            data: (user) =>
                user == null ? const _SignedOut() : _SignedIn(user: user),
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
      children: [
        const Text('Sign in to sync your progress'),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: () => context.push('/sign-in'),
          child: const Text('Sign in'),
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
      children: [
        Text(user.displayName ?? user.email ?? 'Signed in'),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(
          onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          child: const Text('Sign out'),
        ),
      ],
    );
  }
}
