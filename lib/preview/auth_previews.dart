// lib/preview/auth_previews.dart
//
// Design previews for the auth surfaces. Run with:
//   flutter widget-preview start
// (or open the Widget Previews panel in the IDE on Flutter 3.38+).
//
// These are static, provider-free compositions: the previewer runs on
// Flutter Web, so nothing here may import bootstrap, Drift, or the Flame
// ambient layer. The real AuthSheetContent is Riverpod-backed, so the sheet
// is recomposed here from its provider-free building blocks.
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../core/design/tokens/colors.dart';
import '../core/design/tokens/gradients.dart';
import '../core/design/tokens/radii.dart';
import '../core/design/tokens/spacing.dart';
import '../features/auth/presentation/widgets/email_password_form.dart';
import '../features/auth/presentation/widgets/google_sign_in_button.dart';
import '../shared/widgets/lily_pad.dart';
import '../shared/widgets/pond_pill_button.dart';
import '../shared/widgets/pond_text_field.dart';
import '../shared/widgets/pond_text_link.dart';

Widget _stage({double width = 390, double height = 844, required Widget child}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Center(
      child: SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppGradients.pond),
          child: child,
        ),
      ),
    ),
  );
}

@Preview(name: 'Auth sheet (static)')
Widget authSheetPreview() {
  return _stage(
    child: Align(
      alignment: Alignment.bottomCenter,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: AppGradients.pondCard,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadii.lg),
            topRight: Radius.circular(AppRadii.lg),
          ),
          border: Border(top: BorderSide(color: AppColors.settingsBorder)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: SizedBox(
                  width: 40,
                  height: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.settingsBorder,
                      borderRadius:
                          BorderRadius.all(Radius.circular(AppRadii.sm)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Center(
                child: LilyPad(
                  size: 44,
                  palette: LilyPadPalette.teal,
                  shape: PadShape.smooth,
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
              GoogleSignInButton(onPressed: () {}),
              const SizedBox(height: AppSpacing.sm),
              PondPillButton(
                label: 'Continue as guest',
                icon: Icons.person_outline,
                variant: PondPillVariant.quiet,
                onPressed: () {},
              ),
              const SizedBox(height: AppSpacing.sm),
              PondTextLink(label: 'Use email instead', onTap: () {}),
            ],
          ),
        ),
      ),
    ),
  );
}

@Preview(name: 'Auth email form (static)')
Widget authEmailFormPreview() {
  return _stage(
    height: 520,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EmailPasswordForm(
            formKey: GlobalKey<FormState>(),
            emailController: TextEditingController(),
            passwordController: TextEditingController(),
          ),
          const SizedBox(height: AppSpacing.md),
          PondPillButton(label: 'Sign in', onPressed: () {}),
          PondTextLink(label: 'New here? Create an account', onTap: () {}),
          const SizedBox(height: AppSpacing.md),
          const PondTextField(label: 'Standalone field'),
        ],
      ),
    ),
  );
}
