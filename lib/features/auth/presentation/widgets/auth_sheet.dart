import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tokens/durations.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../application/auth_providers.dart';
import 'auth_error_text.dart';
import 'email_password_form.dart';
import 'google_sign_in_button.dart';

/// Opens the sign-in modal: Google first, then guest, then an inline email form.
Future<void> showAuthSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const AuthSheetContent(),
  );
}

/// Body of the auth modal. Auto-closes once a user is signed in (any method).
class AuthSheetContent extends ConsumerStatefulWidget {
  const AuthSheetContent({super.key});

  @override
  ConsumerState<AuthSheetContent> createState() => _AuthSheetContentState();
}

class _AuthSheetContentState extends ConsumerState<AuthSheetContent> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showEmail = false;
  bool _isRegister = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(authControllerProvider.notifier);
    if (_isRegister) {
      await notifier.registerWithEmail(_email.text.trim(), _password.text);
    } else {
      await notifier.signInWithEmail(_email.text.trim(), _password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (prev, next) {
      if (next.asData?.value != null && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });

    final state = ref.watch(authControllerProvider);
    final isLoading = state.isLoading;
    final notifier = ref.read(authControllerProvider.notifier);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.sm,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sign in to save your progress',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          GoogleSignInButton(
            onPressed: isLoading ? null : () => notifier.signInWithGoogle(),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: isLoading ? null : () => notifier.signInWithGuest(),
            icon: const Icon(Icons.person_outline),
            label: const Text('Continue as guest'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => setState(() => _showEmail = !_showEmail),
            child: Text(_showEmail ? 'Hide email sign-in' : 'Use email instead'),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: _EmailSection(
              formKey: _formKey,
              email: _email,
              password: _password,
              isRegister: _isRegister,
              isLoading: isLoading,
              onSubmit: _submitEmail,
              onToggleRegister: () => setState(() => _isRegister = !_isRegister),
            ),
            crossFadeState:
                _showEmail ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: AppDurations.normal,
          ),
          if (state.hasError) ...[
            const SizedBox(height: AppSpacing.sm),
            AuthErrorText(error: state.error!),
          ],
        ],
      ),
    );
  }
}

class _EmailSection extends StatelessWidget {
  const _EmailSection({
    required this.formKey,
    required this.email,
    required this.password,
    required this.isRegister,
    required this.isLoading,
    required this.onSubmit,
    required this.onToggleRegister,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final TextEditingController password;
  final bool isRegister;
  final bool isLoading;
  final Future<void> Function() onSubmit;
  final VoidCallback onToggleRegister;

  @override
  Widget build(BuildContext context) {
    final label = isRegister ? 'Create account' : 'Sign in';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.sm),
        EmailPasswordForm(
          formKey: formKey,
          emailController: email,
          passwordController: password,
        ),
        const SizedBox(height: AppSpacing.sm),
        FilledButton(
          onPressed: isLoading ? null : onSubmit,
          child: Text(label),
        ),
        TextButton(
          onPressed: onToggleRegister,
          child: Text(
            isRegister
                ? 'Have an account? Sign in'
                : 'New here? Create an account',
          ),
        ),
      ],
    );
  }
}
