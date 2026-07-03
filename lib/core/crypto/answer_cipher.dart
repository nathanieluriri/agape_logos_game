import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// Decrypts puzzle-answer tokens produced by the backend `answer_cipher`
/// (AES-256-GCM). Wire token = base64( iv(12) | ciphertext | tag(16) ); the
/// plaintext is JSON `{"w": word, "d": definition|null}`.
///
/// The per-user key never lives in the local DB; it is held in device secure
/// storage (see [AnswerKeyStore]). Decryption happens in memory only, at play
/// time, so answers are never at rest in plaintext.
class AnswerCipher {
  AnswerCipher();

  final AesGcm _algorithm = AesGcm.with256bits();

  static const int _ivBytes = 12;
  static const int _tagBytes = 16;

  /// Decrypts [token] with [keyBytes] (32 bytes) and returns the plaintext
  /// JSON string. Throws if the key is wrong or the token is tampered with.
  Future<String> decrypt(List<int> keyBytes, String token) async {
    final raw = base64Decode(token);
    final iv = raw.sublist(0, _ivBytes);
    final cipherText = raw.sublist(_ivBytes, raw.length - _tagBytes);
    final mac = raw.sublist(raw.length - _tagBytes);
    final clear = await _algorithm.decrypt(
      SecretBox(cipherText, nonce: iv, mac: Mac(mac)),
      secretKey: SecretKey(keyBytes),
    );
    return utf8.decode(clear);
  }

  /// Decrypts an answer token into `(word, definition)`.
  Future<({String word, String? definition})> decryptAnswer(
    List<int> keyBytes,
    String token,
  ) async {
    final json = jsonDecode(await decrypt(keyBytes, token)) as Map;
    return (
      word: json['w'] as String,
      definition: json['d'] as String?,
    );
  }
}
