import 'package:flutter/material.dart';

import '../../../../shared/widgets/pond_pill_button.dart';

/// Pond capsule "continue with Google" action. Disabled (dimmed, ignoring
/// taps) while [onPressed] is null.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  static void _noop() {}

  @override
  Widget build(BuildContext context) {
    return PondPillButton(
      label: 'Continue with Google',
      icon: Icons.login,
      variant: PondPillVariant.quiet,
      enabled: onPressed != null,
      onPressed: onPressed ?? _noop,
    );
  }
}
