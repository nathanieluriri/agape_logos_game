import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/api_client.dart';
import '../domain/challenge_outcome.dart';

/// Function-call transport for multiplayer (contract 8.7). Reads go through the
/// Firestore listeners (see MatchFirestore); every WRITE is a Cloud Function
/// call carrying an `idempotency-key` header. The Bearer token is attached by
/// the Dio AuthInterceptor; offline rejection surfaces as a DioException.
abstract interface class MatchRemote {
  /// POST /matches {settings} -> {matchId, code}. Creator only.
  Future<({String matchId, String code})> create(Map<String, dynamic> settings);

  /// POST /matches/join {code} -> {matchId}. Throws on an unknown/closed code.
  Future<String> join(String code);

  /// POST /matches/:id/ready {ready}.
  Future<void> ready(String matchId, {required bool ready});

  /// POST /matches/:id/start {} (creator force-start).
  Future<void> start(String matchId);

  /// POST /matches/:id/submit {word}. Idempotent per (uid, normalized word).
  Future<void> submit(String matchId, String word);

  /// POST /matches/:id/powerup {kind, eventId}. Returns false on 402 (the caller
  /// owns none of that powerup); true when the event was accepted.
  Future<bool> powerup(String matchId, String kind, {required String eventId});

  /// POST /matches/:id/leave {}.
  Future<void> leave(String matchId);

  /// GET /matches/:id. Pure read, but the server SETTLES the clock while serving
  /// it (countdown -> active once startedAt passes, active -> finished once
  /// endsAt passes). Those transitions are only ever persisted by a request, so
  /// with no player writing (nobody submits a word) the doc would sit on its old
  /// status forever and the listener would never see the match start or end.
  /// The match page pokes this at exactly those two instants.
  Future<void> settle(String matchId);

  /// POST /matches/challenge. mode is 'live' or 'async'.
  Future<ChallengeOutcome> challenge(String toUid, {required String mode});

  /// POST /matches/:id/respond. Accept or decline an incoming challenge.
  Future<void> respondChallenge(String matchId, {required bool accept});
}

class HttpMatchRemote implements MatchRemote {
  HttpMatchRemote(this._api, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final ApiClient _api;
  final Uuid _uuid;

  String _key() => _uuid.v4();

  @override
  Future<({String matchId, String code})> create(
    Map<String, dynamic> settings,
  ) async {
    final res = await _api.request<Map<String, dynamic>>(
      '/matches',
      method: 'POST',
      data: <String, dynamic>{'settings': settings},
      headers: <String, String>{'idempotency-key': _key()},
    );
    final data = res.data ?? const <String, dynamic>{};
    return (matchId: data['matchId'] as String, code: data['code'] as String);
  }

  @override
  Future<String> join(String code) async {
    final res = await _api.request<Map<String, dynamic>>(
      '/matches/join',
      method: 'POST',
      data: <String, dynamic>{'code': code},
      headers: <String, String>{'idempotency-key': _key()},
    );
    return (res.data ?? const <String, dynamic>{})['matchId'] as String;
  }

  @override
  Future<void> ready(String matchId, {required bool ready}) =>
      _post('/matches/$matchId/ready', <String, dynamic>{'ready': ready});

  @override
  Future<void> start(String matchId) =>
      _post('/matches/$matchId/start', const <String, dynamic>{});

  @override
  Future<void> submit(String matchId, String word) {
    final normalized = word.toUpperCase();
    // Idempotent per (uid, word): the uid is implicit in the Bearer token, so
    // keying on the word means a double-tap never double-scores (contract 8.7).
    return _post('/matches/$matchId/submit', <String, dynamic>{
      'word': normalized,
    }, idempotencyKey: 'submit:$matchId:$normalized');
  }

  @override
  Future<bool> powerup(
    String matchId,
    String kind, {
    required String eventId,
  }) async {
    try {
      await _api.request<Map<String, dynamic>>(
        '/matches/$matchId/powerup',
        method: 'POST',
        data: <String, dynamic>{'kind': kind, 'eventId': eventId},
        // Powerup is idempotent per client-supplied event id (contract 8.7),
        // which is also the events/{eventId} doc id the server writes.
        headers: <String, String>{'idempotency-key': eventId},
      );
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 402) return false; // none owned
      rethrow;
    }
  }

  @override
  Future<void> leave(String matchId) =>
      _post('/matches/$matchId/leave', const <String, dynamic>{});

  @override
  Future<void> settle(String matchId) async {
    // The response is discarded on purpose: the settled doc reaches the UI
    // through the Firestore listener, exactly like every other match change.
    await _api.request<Map<String, dynamic>>(
      '/matches/$matchId',
      method: 'GET',
    );
  }

  @override
  Future<ChallengeOutcome> challenge(String toUid, {required String mode}) async {
    try {
      final res = await _api.request<Map<String, dynamic>>(
        '/matches/challenge',
        method: 'POST',
        data: <String, dynamic>{
          'toUid': toUid,
          'settings': <String, dynamic>{
            'mode': mode,
            'difficulty': 'medium',
            'durationSec': 120,
          },
        },
        headers: <String, String>{'idempotency-key': _key()},
      );
      final data = res.data ?? const <String, dynamic>{};
      return ChallengeSent(data['matchId'] as String);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 409) return const ChallengeAlreadyOpen();
      if (status == 404) return const ChallengeNotFriends();
      return const ChallengeUnavailable();
    }
  }

  @override
  Future<void> respondChallenge(String matchId, {required bool accept}) =>
      _post('/matches/$matchId/respond', <String, dynamic>{'accept': accept});

  Future<void> _post(
    String path,
    Map<String, dynamic> body, {
    String? idempotencyKey,
  }) async {
    await _api.request<Map<String, dynamic>>(
      path,
      method: 'POST',
      data: body,
      headers: <String, String>{'idempotency-key': idempotencyKey ?? _key()},
    );
  }
}
