import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/radii.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/pond_pill_button.dart';
import '../../../../shared/widgets/pond_snack.dart';
import '../../application/social_providers.dart';
import '../../domain/friend_request_outcome.dart';
import '../../domain/public_profile.dart';
import 'social_avatar_dot.dart';

/// The "Find friends" pane: a search field over public profiles and an Add
/// action per result. Live-searches `userSearchProvider(query)`.
class UserSearchView extends ConsumerStatefulWidget {
  const UserSearchView({super.key});

  @override
  ConsumerState<UserSearchView> createState() => _UserSearchViewState();
}

class _UserSearchViewState extends ConsumerState<UserSearchView> {
  String _query = '';

  Future<void> _add(PublicProfile user) async {
    final outcome = await ref
        .read(friendActionsControllerProvider.notifier)
        .sendRequest(toUid: user.uid);
    if (!mounted) return;
    showPondSnack(context, switch (outcome) {
      FriendRequestSent() => 'Request sent to ${user.displayName}',
      FriendRequestUserNotFound() => 'That player could not be found.',
      FriendRequestInvalid() => 'You cannot add that player.',
      FriendRequestUnavailable() => 'Could not send the request. Try again.',
    });
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(userSearchProvider(_query));
    final busy = ref.watch(friendActionsControllerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.pillFill,
              borderRadius: AppRadii.pill,
              border: Border.all(color: AppColors.settingsBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: TextField(
                autocorrect: false,
                style: const TextStyle(color: AppColors.padLabel),
                cursorColor: AppColors.padLabel,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search by name or @handle',
                  hintStyle: TextStyle(color: AppColors.padLabelSoft),
                  icon: Icon(Icons.search, color: AppColors.padLabelSoft),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
          ),
        ),
        Expanded(
          child: results.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const _SearchMessage('Could not search right now.'),
            data: (users) {
              if (_query.trim().isEmpty) {
                return const _SearchMessage('Find friends by their name or @handle.');
              }
              if (users.isEmpty) {
                return const _SearchMessage('No public players match that.');
              }
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, i) {
                  final u = users[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        SocialAvatarDot(name: u.displayName),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            '${u.displayName}  @${u.handle}',
                            style: const TextStyle(
                              color: AppColors.padLabel,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        PondPillButton(
                          label: 'Add',
                          enabled: !busy.contains(u.uid),
                          semanticLabel: 'Add ${u.displayName}',
                          onPressed: () => _add(u),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SearchMessage extends StatelessWidget {
  const _SearchMessage(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.padLabelSoft, fontSize: 14),
        ),
      );
}
