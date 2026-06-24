import 'package:flutter/material.dart';

/// Outlined "continue with Google" action. Disabled while [onPressed] is null.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.login),
      label: const Text('Continue with Google'),
    );
  }
}
