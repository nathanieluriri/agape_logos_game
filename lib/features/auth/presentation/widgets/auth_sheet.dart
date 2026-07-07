import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/durations.dart';
import '../../../../core/design/tokens/gradients.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/pond_pill_button.dart';
import '../../../../shared/widgets/pond_text_link.dart';
import '../../application/auth_providers.dart';
import 'auth_error_text.dart';
import 'email_password_form.dart';
import 'google_sign_in_button.dart';

/// Opens the sign-in modal: a pond bottom sheet with Google first, then
/// guest, then an inline email form.
Future<void> showAuthSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.transparent,
    elevation: 0,
    showDragHandle: false,
    barrierColor: AppColors.pondScrim,
    isScrollControlled: true,
    builder: (_) => const AuthSheetContent(),
  );
}

/// Body of the auth modal: a deep-water card rising from the bottom edge.
/// Auto-closes once a user is signed in (any method). While a sign-in is in
/// flight the action pills simply disable; there is no spinner.
class AuthSheetContent extends ConsumerStatefulWidget {
  const AuthSheetContent({super.key});

  @override
  ConsumerState<AuthSheetContent> createState() => _AuthSheetContentState();
}

class _AuthSheetContentState extends ConsumerState<AuthSheetContent> {
  /// Hand-rolled drag bar dimensions (matches the coming-soon sheet).
  static const double _dragBarWidth = 40;
  static const double _dragBarHeight = 4;

  /// Height of the lotus auth mark above the title.
  static const double _authIconSize = 60;

  static const _sheetDecoration = BoxDecoration(
    gradient: AppGradients.pondCard,
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(AppRadii.lg),
      topRight: Radius.circular(AppRadii.lg),
    ),
    border: Border(top: BorderSide(color: AppColors.settingsBorder)),
  );

  static const _dragBarDecoration = BoxDecoration(
    color: AppColors.settingsBorder,
    borderRadius: BorderRadius.all(Radius.circular(AppRadii.sm)),
  );

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

    return DecoratedBox(
      decoration: _sheetDecoration,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
          ),
          // Scrolls when the email section plus keyboard exceed the viewport
          // instead of overflowing the fixed column.
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: SizedBox(
                  width: _dragBarWidth,
                  height: _dragBarHeight,
                  child: DecoratedBox(decoration: _dragBarDecoration),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: SvgPicture.asset(
                  'assets/branding/auth_icon.svg',
                  height: _authIconSize,
                  semanticsLabel: 'Agape Logos',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Sign in to save your progress',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.padLabel,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              GoogleSignInButton(
                onPressed: isLoading ? null : () => notifier.signInWithGoogle(),
              ),
              const SizedBox(height: AppSpacing.sm),
              PondPillButton(
                label: 'Continue as guest',
                icon: Icons.person_outline,
                variant: PondPillVariant.quiet,
                enabled: !isLoading,
                onPressed: () => notifier.signInWithGuest(),
              ),
              const SizedBox(height: AppSpacing.sm),
              PondTextLink(
                label: _showEmail ? 'Hide email sign-in' : 'Use email instead',
                onTap: () => setState(() => _showEmail = !_showEmail),
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
                  onToggleRegister: () =>
                      setState(() => _isRegister = !_isRegister),
                ),
                crossFadeState: _showEmail
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: AppDurations.normal,
              ),
              if (state.hasError) ...[
                const SizedBox(height: AppSpacing.sm),
                AuthErrorText(error: state.error!),
              ],
            ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The collapsible email sign-in / register block inside the sheet.
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
        PondPillButton(
          label: label,
          enabled: !isLoading,
          onPressed: onSubmit,
        ),
        PondTextLink(
          label: isRegister
              ? 'Have an account? Sign in'
              : 'New here? Create an account',
          onTap: onToggleRegister,
        ),
      ],
    );
  }
}
