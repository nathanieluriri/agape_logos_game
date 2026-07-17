import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/friend.dart';
import '../domain/friend_request.dart';
import '../domain/friend_request_outcome.dart';
import '../domain/friends_snapshot.dart';
import '../domain/match_history_entry.dart';
import '../domain/public_profile.dart';
import '../domain/public_profile_detail.dart';
import '../social_config.dart';

/// Thrown by [SocialRemote.publicProfile] when the target is private (403) or
/// not found: the profile page shows a "private profile" state.
class ProfileNotVisible implements Exception {
  const ProfileNotVisible();
}

/// Thin transport for the social endpoints. The Bearer token is attached by the
/// Dio `AuthInterceptor`; offline rejection by the `ConnectivityInterceptor`, so
/// both surface here as a [DioException]. Documented business errors are mapped
/// to typed results (mirrors `HttpStoreRemote`).
abstract interface class SocialRemote {
  Future<void> setPrivacy(bool isPublic, {required String idempotencyKey});
  Future<List<PublicProfile>> searchUsers(String query);
  Future<PublicProfileDetail> publicProfile(String uid);
  Future<FriendRequestOutcome> sendFriendRequest({
    String? toUid,
    String? handle,
    required String idempotencyKey,
  });
  Future<bool> respondToFriendRequest({
    required String fromUid,
    required bool accept,
    required String idempotencyKey,
  });
  Future<FriendsSnapshot> friends();
  Future<List<MatchHistoryEntry>> matchHistory({int? limit});
}

class HttpSocialRemote implements SocialRemote {
  HttpSocialRemote(this._api);

  final ApiClient _api;

  @override
  Future<void> setPrivacy(
    bool isPublic, {
    required String idempotencyKey,
  }) async {
    await _api.request<Map<String, dynamic>>(
      kPrivacyEndpoint,
      method: 'PUT',
      data: <String, dynamic>{'public': isPublic},
      headers: <String, String>{'idempotency-key': idempotencyKey},
    );
  }

  @override
  Future<List<PublicProfile>> searchUsers(String query) async {
    final res = await _api.request<Map<String, dynamic>>(
      '$kUserSearchEndpoint?q=${Uri.encodeQueryComponent(query)}',
      method: 'GET',
    );
    return (res.data?['users'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(PublicProfile.fromJson)
        .toList();
  }

  @override
  Future<PublicProfileDetail> publicProfile(String uid) async {
    try {
      final res = await _api.request<Map<String, dynamic>>(
        publicProfileEndpoint(uid),
        method: 'GET',
      );
      final data = res.data ?? const <String, dynamic>{};
      return PublicProfileDetail(
        profile: PublicProfile.fromJson(
          (data['profile'] as Map<String, dynamic>?) ?? const {},
        ),
        recentMatches: (data['recentMatches'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(MatchHistoryEntry.fromJson)
            .toList(),
      );
    } on DioException catch (e) {
      final int? code = e.response?.statusCode;
      if (code == 403 || code == 404) throw const ProfileNotVisible();
      rethrow;
    }
  }

  @override
  Future<FriendRequestOutcome> sendFriendRequest({
    String? toUid,
    String? handle,
    required String idempotencyKey,
  }) async {
    try {
      await _api.request<Map<String, dynamic>>(
        kFriendRequestEndpoint,
        method: 'POST',
        data: <String, dynamic>{
          if (toUid != null) 'toUid': toUid,
          if (handle != null) 'handle': handle,
        },
        headers: <String, String>{'idempotency-key': idempotencyKey},
      );
      return const FriendRequestSent();
    } on DioException catch (e) {
      final int? code = e.response?.statusCode;
      if (code == 404) return const FriendRequestUserNotFound();
      if (code == 400) return const FriendRequestInvalid();
      return const FriendRequestUnavailable();
    }
  }

  @override
  Future<bool> respondToFriendRequest({
    required String fromUid,
    required bool accept,
    required String idempotencyKey,
  }) async {
    try {
      await _api.request<Map<String, dynamic>>(
        kFriendRespondEndpoint,
        method: 'POST',
        data: <String, dynamic>{'fromUid': fromUid, 'accept': accept},
        headers: <String, String>{'idempotency-key': idempotencyKey},
      );
      return true;
    } on DioException {
      return false;
    }
  }

  @override
  Future<FriendsSnapshot> friends() async {
    final res = await _api.request<Map<String, dynamic>>(
      kFriendsEndpoint,
      method: 'GET',
    );
    final data = res.data ?? const <String, dynamic>{};
    return FriendsSnapshot(
      friends: (data['friends'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Friend.fromJson)
          .toList(),
      requests: (data['requests'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(FriendRequest.fromJson)
          .toList(),
    );
  }

  @override
  Future<List<MatchHistoryEntry>> matchHistory({int? limit}) async {
    final res = await _api.request<Map<String, dynamic>>(
      limit == null ? kMatchesEndpoint : '$kMatchesEndpoint?limit=$limit',
      method: 'GET',
    );
    return (res.data?['history'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(MatchHistoryEntry.fromJson)
        .toList();
  }
}
