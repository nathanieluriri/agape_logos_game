import 'package:flutter/widgets.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../domain/auth_failure.dart';

/// Renders a friendly message for an auth error in the pond danger tone.
/// Robust to non-AuthFailure errors (e.g. an unexpected Google exception).
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
      style: const TextStyle(
        color: AppColors.dangerOnPond,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
