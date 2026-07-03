import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/pond_background.dart';
import '../../../../shared/widgets/pond_dialog.dart';
import '../../../../shared/widgets/pond_pill_button.dart';
import '../../../../shared/widgets/pond_snack.dart';
import '../../../../shared/widgets/pond_stage.dart';
import '../../../../shared/widgets/pond_text_field.dart';
import '../../../../shared/widgets/pond_text_link.dart';
import '../../application/auth_providers.dart';
import '../widgets/auth_error_text.dart';
import '../widgets/auth_page_header.dart';
import '../widgets/email_password_form.dart';
import '../widgets/google_sign_in_button.dart';

/// Optional sign-in / register screen on the pond. Closes itself once a user
/// is signed in. While a request is in flight the pills disable; no spinner.
class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  /// Owned by the state (not the dialog) so it outlives the dialog's exit
  /// transition; disposing it as the route animates out trips the IME.
  final _resetEmail = TextEditingController();
  bool _isRegister = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _resetEmail.dispose();
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
    _resetEmail.text = _email.text.trim();
    // The pills are built with the page context, so popping must target the
    // root navigator (where showPondDialog pushed the dialog route).
    final email = await showPondDialog<String>(
      context: context,
      title: 'Reset password',
      content: PondTextField(
        controller: _resetEmail,
        label: 'Email',
        keyboardType: TextInputType.emailAddress,
      ),
      actions: [
        PondPillButton(
          label: 'Cancel',
          variant: PondPillVariant.quiet,
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
        PondPillButton(
          label: 'Send',
          onPressed: () => Navigator.of(context, rootNavigator: true)
              .pop(_resetEmail.text.trim()),
        ),
      ],
    );
    if (email == null || email.isEmpty) return;
    await ref.read(authControllerProvider.notifier).sendPasswordReset(email);
    if (!mounted) return;
    showPondSnack(context, 'If that email exists, a reset link is on its way.');
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
      body: PondBackground(
        child: PondStage(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthPageHeader(title: submitLabel),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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
                    PondPillButton(
                      label: submitLabel,
                      enabled: !isLoading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    GoogleSignInButton(
                      onPressed: isLoading
                          ? null
                          : () => ref
                              .read(authControllerProvider.notifier)
                              .signInWithGoogle(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PondTextLink(
                      label: _isRegister
                          ? 'Have an account? Sign in'
                          : 'New here? Create an account',
                      onTap: () => setState(() => _isRegister = !_isRegister),
                    ),
                    PondTextLink(
                      label: 'Forgot password?',
                      enabled: !isLoading,
                      onTap: _showResetDialog,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
