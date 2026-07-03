import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/network/api_client.dart';

/// Fetches and caches the per-user answer-decryption key.
///
/// The key is delivered once by `GET /me/answer-key` (authed, over TLS) and
/// persisted in device **secure storage** (Keychain / Keystore), deliberately
/// NOT in the Drift cache: a dump of the local DB then reveals only ciphertext,
/// not the key that unlocks it. Held in memory after first load so play-time
/// decryption is cheap and works offline.
class AnswerKeyStore {
  AnswerKeyStore(this._api, {FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final ApiClient _api;
  final FlutterSecureStorage _storage;
  final Map<String, List<int>> _memo = <String, List<int>>{};

  String _slot(String uid) => 'answer_key_$uid';

  /// The 32-byte key for [uid]: memo -> secure storage -> `GET /me/answer-key`.
  /// Returns null when it is neither cached nor fetchable (offline first run).
  Future<List<int>?> keyFor(String uid) async {
    final memo = _memo[uid];
    if (memo != null) return memo;

    final stored = await _storage.read(key: _slot(uid));
    if (stored != null) {
      final bytes = base64Decode(stored);
      _memo[uid] = bytes;
      return bytes;
    }

    try {
      final res =
          await _api.request<Map<String, dynamic>>('/me/answer-key', method: 'GET');
      final b64 = res.data?['key'] as String?;
      if (b64 == null) return null;
      await _storage.write(key: _slot(uid), value: b64);
      final bytes = base64Decode(b64);
      _memo[uid] = bytes;
      return bytes;
    } on DioException catch (e) {
      logger.info('answer key fetch skipped (offline): ${e.message}');
      return null;
    }
  }

  /// Drops the cached key (on sign-out / account deletion).
  Future<void> clear(String uid) async {
    _memo.remove(uid);
    await _storage.delete(key: _slot(uid));
  }
}
