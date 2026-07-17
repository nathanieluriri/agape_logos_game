import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/purchase_outcome.dart';
import '../domain/store_item.dart';

/// Thin transport for the store endpoints. The Bearer token is attached by the
/// Dio `AuthInterceptor`; offline rejection is handled by the
/// `ConnectivityInterceptor`, so both surface here as a [DioException].
///
/// Dio's default `validateStatus` throws on any non-2xx, so the documented
/// business errors (400 unknown item, 402 insufficient coins) arrive as
/// [DioException]s and are mapped to [PurchaseOutcome]s here rather than thrown.
abstract interface class StoreRemote {
  Future<List<StoreItem>> catalog();
  Future<Map<String, int>> inventory();
  Future<PurchaseOutcome> purchase({
    required String idempotencyKey,
    required String itemId,
    required int quantity,
  });
}

class HttpStoreRemote implements StoreRemote {
  HttpStoreRemote(this._api);

  final ApiClient _api;

  @override
  Future<List<StoreItem>> catalog() async {
    final res = await _api.request<Map<String, dynamic>>(
      '/store',
      method: 'GET',
    );
    final items = (res.data?['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(StoreItem.fromJson)
        .toList();
    return items;
  }

  @override
  Future<Map<String, int>> inventory() async {
    final res = await _api.request<Map<String, dynamic>>(
      '/me/inventory',
      method: 'GET',
    );
    return _asCounts(res.data?['inventory']);
  }

  @override
  Future<PurchaseOutcome> purchase({
    required String idempotencyKey,
    required String itemId,
    required int quantity,
  }) async {
    try {
      final res = await _api.request<Map<String, dynamic>>(
        '/store/purchase',
        method: 'POST',
        data: <String, dynamic>{'itemId': itemId, 'quantity': quantity},
        headers: <String, String>{'idempotency-key': idempotencyKey},
      );
      final data = res.data ?? const <String, dynamic>{};
      return PurchaseSuccess(
        coins: (data['coins'] as num?)?.toInt() ?? 0,
        inventory: _asCounts(data['inventory']),
        charged: (data['charged'] as num?)?.toInt() ?? 0,
        replay: data['replay'] as bool? ?? false,
      );
    } on DioException catch (e) {
      final int? code = e.response?.statusCode;
      final Object? body = e.response?.data;
      if (code == 402) {
        final map = body is Map<String, dynamic> ? body : const {};
        return PurchaseInsufficientCoins(
          cost: (map['cost'] as num?)?.toInt() ?? 0,
          coins: (map['coins'] as num?)?.toInt() ?? 0,
        );
      }
      if (code == 400) return const PurchaseUnknownItem();
      // No response (offline / timeout) or a 401/403/5xx: not chargeable now.
      return const PurchaseUnavailable();
    }
  }

  /// Coerces a `Record<string, number>` JSON object into a Dart `int` map,
  /// dropping any non-numeric entries defensively.
  static Map<String, int> _asCounts(Object? raw) {
    if (raw is! Map) return <String, int>{};
    final out = <String, int>{};
    raw.forEach((key, value) {
      if (key is String && value is num) out[key] = value.toInt();
    });
    return out;
  }
}
