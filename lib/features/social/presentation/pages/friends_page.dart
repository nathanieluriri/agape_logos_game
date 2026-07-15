import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tokens/colors.dart';
import '../../../../core/design/tokens/spacing.dart';
import '../../../../shared/widgets/pond_background.dart';
import '../../../../shared/widgets/pond_page_header.dart';
import '../../../../shared/widgets/pond_pill_button.dart';
import '../../../../shared/widgets/pond_stage.dart';
import '../../../../core/notifications/push_providers.dart';
import '../../../auth/application/auth_providers.dart';
import '../../application/social_providers.dart';
import '../../social_config.dart';
import '../widgets/friend_request_tile.dart';
import '../widgets/friend_tile.dart';
import '../widgets/user_search_view.dart';

/// Which pane the Friends screen opens on.
enum FriendsTab { friends, requests, find }

/// Friends hub: friends list, incoming requests, and find-a-friend search. Thin
/// composition of Task-9 providers and Task-10 widgets.
class FriendsPage extends ConsumerStatefulWidget {
  const FriendsPage({super.key, this.initialTab = FriendsTab.friends});

  final FriendsTab initialTab;

  @override
  ConsumerState<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends ConsumerState<FriendsPage> {
  late FriendsTab _tab = widget.initialTab;
  bool _askedForPush = false;

  @override
  void initState() {
    super.initState();
    // Lazy permission: the first deliberate opt-in to notifications happens when
    // the user opens Friends, not at cold start. Fires once per mount and only
    // when signed in. Registration is idempotent (backend keys by token).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_askedForPush) return;
      final uid = ref.read(currentUserProvider)?.uid;
      if (uid == null) return;
      _askedForPush = true;
      ref.read(pushServiceProvider).registerForUser(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      backgroundColor: AppColors.transparent,
      body: PondBackground(
        // This page owns its scrolling (the panes are ListViews), so the stage
        // must not wrap it in SingleChildScrollView + IntrinsicHeight.
        child: PondStage.fill(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PondPageHeader(title: 'Friends'),
              const SizedBox(height: AppSpacing.md),
              if (user == null)
                const Expanded(child: _SignedOut())
              else ...[
                // PLAN: guest accounts (user.isAnonymous) can be lost on reinstall
                // because their uid is anonymous. Prompt them to link a Google or
                // email account before relying on friendships surviving a wipe.
                if (user.isAnonymous) const _GuestNotice(),
                _SegmentBar(
                  tab: _tab,
                  requestCount: ref.watch(friendRequestsProvider).length,
                  onChanged: (t) => setState(() => _tab = t),
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(child: _pane(_tab)),
              ],
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pane(FriendsTab tab) => switch (tab) {
    FriendsTab.friends => const _FriendsList(),
    FriendsTab.requests => const _RequestsList(),
    FriendsTab.find => const UserSearchView(),
  };
}

class _SegmentBar extends StatelessWidget {
  const _SegmentBar({
    required this.tab,
    required this.requestCount,
    required this.onChanged,
  });

  final FriendsTab tab;
  final int requestCount;
  final ValueChanged<FriendsTab> onChanged;

  @override
  Widget build(BuildContext context) {
    PondPillButton seg(String label, FriendsTab value) => PondPillButton(
      label: label,
      variant: tab == value ? PondPillVariant.primary : PondPillVariant.quiet,
      onPressed: () => onChanged(value),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          seg('Friends', FriendsTab.friends),
          seg(
            requestCount > 0 ? 'Requests ($requestCount)' : 'Requests',
            FriendsTab.requests,
          ),
          seg('Find', FriendsTab.find),
        ],
      ),
    );
  }
}

class _FriendsList extends ConsumerWidget {
  const _FriendsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(liveFriendsProvider);
    return friends.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const _Empty('Could not load your friends.'),
      data: (list) => list.isEmpty
          ? const _Empty('No friends yet. Use Find to add some.')
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(liveFriendsProvider),
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, i) => FriendTile(
                  friend: list[i],
                  onTap: () => context.push(publicProfileRoute(list[i].uid)),
                ),
              ),
            ),
    );
  }
}

class _RequestsList extends ConsumerWidget {
  const _RequestsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(friendRequestsProvider);
    final busy = ref.watch(friendActionsControllerProvider);
    if (requests.isEmpty) return const _Empty('No pending requests.');
    final actions = ref.read(friendActionsControllerProvider.notifier);
    return ListView.builder(
      itemCount: requests.length,
      itemBuilder: (context, i) {
        final r = requests[i];
        return FriendRequestTile(
          request: r,
          busy: busy.contains(r.fromUid),
          onAccept: () => actions.respond(fromUid: r.fromUid, accept: true),
          onDecline: () => actions.respond(fromUid: r.fromUid, accept: false),
        );
      },
    );
  }
}

class _GuestNotice extends StatelessWidget {
  const _GuestNotice();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(
      AppSpacing.md,
      0,
      AppSpacing.md,
      AppSpacing.sm,
    ),
    child: Text(
      'You are playing as a guest. Link a Google or email account in Settings '
      'so your friends are not lost if you reinstall.',
      style: TextStyle(color: AppColors.padLabelSoft, fontSize: 12),
    ),
  );
}

class _SignedOut extends StatelessWidget {
  const _SignedOut();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Sign in to add friends and see your match history.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.padLabelSoft, fontSize: 15),
          ),
          const SizedBox(height: AppSpacing.lg),
          PondPillButton(
            label: 'Sign in',
            onPressed: () => context.push('/sign-in'),
          ),
        ],
      ),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.padLabelSoft, fontSize: 14),
      ),
    ),
  );
}
