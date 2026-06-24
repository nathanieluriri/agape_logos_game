import 'dart:convert';

import 'package:dio/dio.dart';

import '../../features/auth/domain/auth_repository.dart';
import '../network/api_client.dart';
import '../storage/app_database.dart';
import 'sync_engine.dart';

/// Turns one queued [PendingMutation] into an authenticated request and maps the
/// result to a [SendOutcome]. Riverpod-free and network-injected so it is unit
/// testable, and reused unchanged by the 2c background isolate.
///
/// Auth: signed out returns [SendOutcome.transient] (keeps the mutation queued;
/// sync is required-for-sync, optional-for-play). The Bearer token itself is
/// attached by the Dio `AuthInterceptor`, not here.
class HttpMutationSender {
  HttpMutationSender({required this.api, required this.auth});

  final ApiClient api;
  final AuthRepository auth;

  Future<SendOutcome> send(PendingMutation row) async {
    if (auth.currentUser == null) return SendOutcome.transient;
    try {
      final Response<dynamic> res = await api.request<dynamic>(
        row.endpoint,
        method: row.method,
        data: jsonDecode(row.payloadJson),
        headers: <String, String>{'idempotency-key': row.idempotencyKey},
      );
      final int code = res.statusCode ?? 0;
      if (code >= 200 && code < 300) return SendOutcome.success;
      return _map(code);
    } on DioException catch (e) {
      final int? code = e.response?.statusCode;
      return code == null ? SendOutcome.transient : _map(code);
    }
  }

  /// An ID-token blip (401/403), a timeout (408), or a rate-limit (429) is
  /// recoverable, as is any 5xx. Only a malformed request (other 4xx) is
  /// permanent.
  SendOutcome _map(int code) =>
      (code == 401 || code == 403 || code == 408 || code == 429 || code >= 500)
          ? SendOutcome.transient
          : SendOutcome.permanent;
}
