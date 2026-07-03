import 'package:agape_logos_game/core/storage/app_database.dart';
import 'package:agape_logos_game/core/storage/storage_providers.dart';
import 'package:agape_logos_game/features/auth/application/auth_providers.dart';
import 'package:agape_logos_game/features/auth/domain/auth_user.dart';
import 'package:agape_logos_game/features/profile/data/profile_mappers.dart';
import 'package:agape_logos_game/features/profile/domain/profile.dart';
import 'package:agape_logos_game/features/rewards/application/rewards_providers.dart';
import 'package:agape_logos_game/features/rewards/data/rewards_remote.dart';
import 'package:agape_logos_game/features/rewards/domain/claim_result.dart';
import 'package:agape_logos_game/features/rewards/domain/reward_status.dart';
import 'package:agape_logos_game/features/rewards/presentation/widgets/reward_timer_pad.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Profile _profile(String uid, {int coins = 0}) => Profile(
      uid: uid,
      displayName: 'Player',
      avatarId: 'avatar_01',
      locale: 'en',
      soundEnabled: true,
      musicEnabled: true,
      highestLevel: 6,
      totalScore: 0,
      coins: coins,
      createdAt: 1000,
      updatedAt: 2000,
    );

RewardStatus _status({
  required bool unlocked,
  required bool claimable,
  int nextMs = 0,
  int minLevel = 5,
}) =>
    RewardStatus(
      unlocked: unlocked,
      minLevel: minLevel,
      level: 6,
      coins: CoinReward(amount: 400, claimable: claimable, nextClaimInMs: nextMs),
      powerup: PowerupReward(claimable: false, nextClaimInMs: nextMs),
    );

class _FakeRewardsRemote implements RewardsRemote {
  _FakeRewardsRemote(this._status, {ClaimResult? claim})
      : _claim = claim ?? const ClaimUnavailable();
  final RewardStatus _status;
  final ClaimResult _claim;
  int claimCoinsCalls = 0;

  @override
  Future<RewardStatus> status() async => _status;

  @override
  Future<ClaimResult> claimCoins() async {
    claimCoinsCalls++;
    return _claim;
  }

  @override
  Future<ClaimResult> claimPowerup() async => _claim;
}

Widget _wrap(AppDatabase db, _FakeRewardsRemote remote) => ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(const AuthUser(uid: 'u1')),
        rewardsRemoteProvider.overrideWithValue(remote),
        appDatabaseProvider.overrideWithValue(db),
      ],
      child: const MaterialApp(home: Scaffold(body: RewardTimerPad())),
    );

void main() {
  testWidgets('shows a locked chip before rewards unlock', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final remote = _FakeRewardsRemote(_status(unlocked: false, claimable: false));

    await tester.pumpWidget(_wrap(db, remote));
    await tester.pump();
    await tester.pump();

    expect(find.text('Daily gift unlocks at Lv.5'), findsOneWidget);
  });

  testWidgets('claimable state claims coins and shows a snack', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.cachedProfileDao.upsert(profileToCompanion(_profile('u1', coins: 500)));
    final remote = _FakeRewardsRemote(
      _status(unlocked: true, claimable: true),
      claim: const ClaimCoinsSuccess(claimed: 400, coins: 900, nextClaimInMs: 0),
    );

    await tester.pumpWidget(_wrap(db, remote));
    await tester.pump();
    await tester.pump();

    expect(find.text('Claim'), findsOneWidget);

    await tester.tap(find.text('Claim'));
    await tester.pump(); // busy
    await tester.pump(); // claim + write-through + refresh
    await tester.pump(); // snack

    expect(remote.claimCoinsCalls, 1);
    expect(find.text('Claimed 400 coins!'), findsOneWidget);
    final row = await db.cachedProfileDao.read('u1');
    expect(row?.coins, 900);
  });

  testWidgets('cooldown state shows a live countdown', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final remote = _FakeRewardsRemote(
      _status(unlocked: true, claimable: false, nextMs: 3 * 60 * 60 * 1000),
    );

    await tester.pumpWidget(_wrap(db, remote));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Next gift in'), findsOneWidget);

    // Unmount so the 1s periodic countdown timer is cancelled before teardown.
    await tester.pumpWidget(const SizedBox());
  });
}
