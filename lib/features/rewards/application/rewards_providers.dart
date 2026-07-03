import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../../../core/storage/storage_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/rewards_remote.dart';
import '../domain/claim_result.dart';
import '../domain/reward_status.dart';

final rewardsRemoteProvider = Provider<RewardsRemote>(
  (ref) => HttpRewardsRemote(ref.watch(apiClientProvider)),
);

/// The home screen's claim state. Null when signed out; otherwise the latest
/// `GET /rewards` snapshot. Claims run through here so the coin balance and the
/// countdown both refresh from server truth after a claim.
class RewardStatusController extends AsyncNotifier<RewardStatus?> {
  @override
  Future<RewardStatus?> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return null;
    return ref.watch(rewardsRemoteProvider).status();
  }

  /// Re-reads `GET /rewards`. Cheap and side-effect-free on the server.
  Future<void> refresh() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = const AsyncData<RewardStatus?>(null);
      return;
    }
    // Refetch in place: keep the current snapshot visible during the request so
    // the home pad does not flicker between claimable and countdown.
    state = await AsyncValue.guard(
      () => ref.read(rewardsRemoteProvider).status(),
    );
  }

  /// Claims the 72h coin reward. On success writes the authoritative balance
  /// through to the cached profile (so the coin pill updates at once), then
  /// refreshes the countdown. Returns the result for the caller to surface.
  Future<ClaimResult> claimCoins() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return const ClaimUnavailable();

    final result = await ref.read(rewardsRemoteProvider).claimCoins();
    if (result is ClaimCoinsSuccess) {
      await ref
          .read(appDatabaseProvider)
          .cachedProfileDao
          .setCoins(user.uid, result.coins);
    }
    // Any definitive answer (granted, or a cooldown the server now knows about)
    // means our local snapshot is stale; unavailable leaves it as-is.
    if (result is! ClaimUnavailable) await refresh();
    return result;
  }

  /// Claims the weekly powerup. The grant lands in the server inventory (the
  /// store reads it on next open); here we just refresh the countdown.
  Future<ClaimResult> claimPowerup() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return const ClaimUnavailable();

    final result = await ref.read(rewardsRemoteProvider).claimPowerup();
    if (result is! ClaimUnavailable) await refresh();
    return result;
  }
}

final rewardStatusControllerProvider =
    AsyncNotifierProvider<RewardStatusController, RewardStatus?>(
  RewardStatusController.new,
);
