import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/claim_result.dart';
import '../domain/reward_status.dart';

/// Thin transport for the rewards endpoints. Business errors (403 locked, 409 on
/// cooldown) arrive as [DioException]s (Dio throws on non-2xx) and are mapped to
/// [ClaimResult]s here. A missing response (offline / timeout) maps to
/// [ClaimUnavailable].
abstract interface class RewardsRemote {
  Future<RewardStatus> status();
  Future<ClaimResult> claimCoins();
  Future<ClaimResult> claimPowerup();
}

class HttpRewardsRemote implements RewardsRemote {
  HttpRewardsRemote(this._api);

  final ApiClient _api;

  @override
  Future<RewardStatus> status() async {
    final res = await _api.request<Map<String, dynamic>>(
      '/rewards',
      method: 'GET',
    );
    return RewardStatus.fromJson(res.data ?? const {});
  }

  @override
  Future<ClaimResult> claimCoins() async {
    try {
      final res = await _api.request<Map<String, dynamic>>(
        '/rewards/claim-coins',
        method: 'POST',
      );
      final data = res.data ?? const <String, dynamic>{};
      return ClaimCoinsSuccess(
        claimed: (data['claimed'] as num?)?.toInt() ?? 0,
        coins: (data['coins'] as num?)?.toInt() ?? 0,
        nextClaimInMs: (data['nextClaimInMs'] as num?)?.toInt() ?? 0,
      );
    } on DioException catch (e) {
      return _mapClaimError(e);
    }
  }

  @override
  Future<ClaimResult> claimPowerup() async {
    try {
      final res = await _api.request<Map<String, dynamic>>(
        '/rewards/claim-powerup',
        method: 'POST',
      );
      final data = res.data ?? const <String, dynamic>{};
      return ClaimPowerupSuccess(
        granted: data['granted'] as String? ?? '',
        inventory: _asCounts(data['inventory']),
        nextClaimInMs: (data['nextClaimInMs'] as num?)?.toInt() ?? 0,
      );
    } on DioException catch (e) {
      return _mapClaimError(e);
    }
  }

  ClaimResult _mapClaimError(DioException e) {
    final int? code = e.response?.statusCode;
    final Object? body = e.response?.data;
    final map = body is Map<String, dynamic> ? body : const {};
    if (code == 403) {
      return ClaimLocked(minLevel: (map['minLevel'] as num?)?.toInt() ?? 0);
    }
    if (code == 409) {
      return ClaimOnCooldown(
        nextClaimInMs: (map['nextClaimInMs'] as num?)?.toInt() ?? 0,
      );
    }
    return const ClaimUnavailable();
  }

  static Map<String, int> _asCounts(Object? raw) {
    if (raw is! Map) return <String, int>{};
    final out = <String, int>{};
    raw.forEach((key, value) {
      if (key is String && value is num) out[key] = value.toInt();
    });
    return out;
  }
}
