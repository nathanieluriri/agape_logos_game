import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/application/auth_providers.dart';
import '../../../social/application/social_providers.dart';
import 'settings_action_row.dart';
import 'settings_switch_row.dart';

/// Settings row for the "make my profile public" flag, wired to
/// `profilePrivacyControllerProvider` -> `PUT /me/privacy`. When signed out it
/// becomes a "sign in" action row instead of a dead switch.
class PublicProfileSwitchRow extends ConsumerWidget {
  const PublicProfileSwitchRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return SettingsActionRow(
        label: 'Sign in to manage your public profile',
        onTap: () => context.push('/sign-in'),
      );
    }
    final isPublic = ref.watch(profilePrivacyControllerProvider).value ?? false;
    return SettingsSwitchRow(
      label: 'Public profile',
      value: isPublic,
      onChanged: (v) =>
          ref.read(profilePrivacyControllerProvider.notifier).setPublic(v),
    );
  }
}
