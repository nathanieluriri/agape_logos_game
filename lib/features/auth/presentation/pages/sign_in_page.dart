import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/spacing.dart';
import '../../application/auth_providers.dart';
import '../widgets/auth_error_text.dart';
import '../widgets/email_password_form.dart';
import '../widgets/google_sign_in_button.dart';

/// Optional sign-in / register screen. Closes itself once a user is signed in.
class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isRegister = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(authControllerProvider.notifier);
    if (_isRegister) {
      await notifier.registerWithEmail(_email.text.trim(), _password.text);
    } else {
      await notifier.signInWithEmail(_email.text.trim(), _password.text);
    }
  }

  Future<void> _showResetDialog() async {
    final controller = TextEditingController(text: _email.text.trim());
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset password'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (email == null || email.isEmpty) return;
    await ref.read(authControllerProvider.notifier).sendPasswordReset(email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('If that email exists, a reset link is on its way.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (prev, next) {
      if (next.asData?.value != null && context.canPop()) context.pop();
    });

    final state = ref.watch(authControllerProvider);
    final isLoading = state.isLoading;
    final submitLabel = _isRegister ? 'Create account' : 'Sign in';

    return Scaffold(
      appBar: AppBar(title: Text(submitLabel)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EmailPasswordForm(
              formKey: _formKey,
              emailController: _email,
              passwordController: _password,
            ),
            const SizedBox(height: AppSpacing.md),
            if (state.hasError) AuthErrorText(error: state.error!),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              onPressed: isLoading ? null : _submit,
              child: isLoading
                  ? const SizedBox.square(
                      dimension: AppSpacing.md,
                      child: CircularProgressIndicator(),
                    )
                  : Text(submitLabel),
            ),
            const SizedBox(height: AppSpacing.sm),
            GoogleSignInButton(
              onPressed: isLoading
                  ? null
                  : () =>
                      ref.read(authControllerProvider.notifier).signInWithGoogle(),
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: () => setState(() => _isRegister = !_isRegister),
              child: Text(
                _isRegister
                    ? 'Have an account? Sign in'
                    : 'New here? Create an account',
              ),
            ),
            TextButton(
              onPressed: isLoading ? null : _showResetDialog,
              child: const Text('Forgot password?'),
            ),
          ],
        ),
      ),
    );
  }
}
