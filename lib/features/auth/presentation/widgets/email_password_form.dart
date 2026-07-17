import 'package:flutter/material.dart';

import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/pond_text_field.dart';

/// Email + password fields with validation, styled as pond text inputs.
/// Stateless: the parent owns the controllers and form key so it controls
/// submission.
class EmailPasswordForm extends StatelessWidget {
  const EmailPasswordForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your email';
    if (!v.contains('@')) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').length < 6) return 'At least 6 characters';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PondTextField(
            controller: emailController,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            validator: _validateEmail,
          ),
          const SizedBox(height: AppSpacing.md),
          PondTextField(
            controller: passwordController,
            label: 'Password',
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            validator: _validatePassword,
          ),
        ],
      ),
    );
  }
}
