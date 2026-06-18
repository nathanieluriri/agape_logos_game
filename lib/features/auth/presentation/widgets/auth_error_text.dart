import 'package:flutter/material.dart';

import '../../domain/auth_failure.dart';

/// Renders a friendly message for an auth error. Robust to non-AuthFailure
/// errors (e.g. an unexpected Google exception).
class AuthErrorText extends StatelessWidget {
  const AuthErrorText({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final message = error is AuthFailure
        ? (error as AuthFailure).message
        : 'Something went wrong. Please try again.';
    return Text(
      message,
      textAlign: TextAlign.center,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    );
  }
}
