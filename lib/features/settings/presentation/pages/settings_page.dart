import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/coming_soon_sheet.dart';
import '../../../../shared/widgets/pond_background.dart';
import '../../../../shared/widgets/pond_dialog.dart';
import '../../../../shared/widgets/pond_loader.dart';
import '../../../../shared/widgets/pond_pill_button.dart';
import '../../../../shared/widgets/pond_snack.dart';
import '../../../../shared/widgets/pond_stage.dart';
import '../../../auth/application/auth_providers.dart';
import '../../../auth/domain/auth_failure.dart';
import '../../application/settings_providers.dart';
import '../widgets/settings_action_row.dart';
import '../widgets/settings_header.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_switch_row.dart';

/// App version shown in the About section. Keep in sync with pubspec `version`.
const String kAppVersion = '0.2.0';

/// The settings screen: a routed, pond-themed page (replaces the old modal).
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    return Scaffold(
      body: PondBackground(
        child: PondStage(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SettingsHeader(title: 'Settings'),
              const SizedBox(height: AppSpacing.lg),
              settings.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(
                    child: PondLoader(
                      label: 'Loading settings',
                    ),
                  ),
                ),
                error: (_, __) => const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Text('Could not load settings.',
                      style: TextStyle(color: AppColors.padLabelSoft)),
                ),
                data: (s) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SettingsSection(
                      title: 'Sound',
                      children: [
                        SettingsSwitchRow(
                          label: 'Sound effects',
                          value: s.soundEffects,
                          onChanged: controller.setSoundEffects,
                        ),
                        SettingsSwitchRow(
                          label: 'Music',
                          value: s.music,
                          onChanged: controller.setMusic,
                        ),
                      ],
                    ),
                    SettingsSection(
                      title: 'Notifications',
                      children: [
                        SettingsSwitchRow(
                          label: 'Notifications',
                          value: s.notifications,
                          onChanged: controller.setNotifications,
                        ),
                      ],
                    ),
                    SettingsSection(
                      title: 'Game',
                      children: [
                        SettingsSwitchRow(
                          label: 'Haptics',
                          value: s.haptics,
                          onChanged: controller.setHaptics,
                        ),
                      ],
                    ),
                    const _AccountSection(),
                    SettingsSection(
                      title: 'About',
                      children: [
                        SettingsActionRow(
                          label: 'Privacy Policy',
                          onTap: () =>
                              showComingSoon(context, 'Privacy Policy'),
                        ),
                        SettingsActionRow(
                          label: 'Terms of Service',
                          onTap: () =>
                              showComingSoon(context, 'Terms of Service'),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm),
                          child: Text('Version $kAppVersion',
                              style: TextStyle(
                                  color: AppColors.padLabelSoft, fontSize: 13)),
                        ),
                      ],
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

class _AccountSection extends ConsumerWidget {
  const _AccountSection();

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    // The pills are built with the page context, so popping must target the
    // root navigator (where showPondDialog pushed the dialog route).
    final confirmed = await showPondDialog<bool>(
      context: context,
      title: 'Delete account?',
      body: 'This permanently deletes your account and local progress. '
          'This cannot be undone.',
      actions: [
        PondPillButton(
          label: 'Cancel',
          variant: PondPillVariant.quiet,
          onPressed: () =>
              Navigator.of(context, rootNavigator: true).pop(false),
        ),
        PondPillButton(
          label: 'Delete',
          variant: PondPillVariant.danger,
          onPressed: () =>
              Navigator.of(context, rootNavigator: true).pop(true),
        ),
      ],
    );
    if (confirmed != true) return;

    await ref.read(authControllerProvider.notifier).deleteAccount();
    if (!context.mounted) return;

    final state = ref.read(authControllerProvider);
    if (state.hasError) {
      final error = state.error;
      if (error == AuthFailure.requiresRecentLogin) {
        showPondSnack(
            context, 'Please sign in again, then retry deleting your account.');
        context.push('/sign-in');
      } else {
        final msg =
            error is AuthFailure ? error.message : 'Could not delete account.';
        showPondSnack(context, msg);
      }
      return;
    }
    context.go('/');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).asData?.value;
    return SettingsSection(
      title: 'Account',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Text(
            user == null
                ? 'Not signed in'
                : (user.displayName ?? user.email ?? 'Signed in'),
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: AppColors.padLabel),
          ),
        ),
        if (user == null)
          SettingsActionRow(
            label: 'Sign in',
            onTap: () => context.push('/sign-in'),
          )
        else ...[
          SettingsActionRow(
            label: 'Sign out',
            onTap: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
          SettingsActionRow(
            label: 'Delete account',
            danger: true,
            icon: Icons.delete_outline,
            onTap: () => _confirmDelete(context, ref),
          ),
        ],
      ],
    );
  }
}
