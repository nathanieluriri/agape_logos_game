import * as crypto from "crypto";

// Per-user, at-rest encryption for puzzle answers so the plaintext never leaves
// the server: the client stores only ciphertext and decrypts in memory at play
// time. This raises the bar against casual cheating (reading the local DB or
// sniffing traffic). It is NOT unbreakable: the per-user key is delivered to the
// authenticated device, so a determined reverse-engineer can still recover it.
//
// Wire format for one answer token: base64( iv(12) | ciphertext | tag(16) ),
// AES-256-GCM. The plaintext is JSON: {"w": word, "d": definition|null}.

const KEY_BYTES = 32; // AES-256
const IV_BYTES = 12; // GCM standard nonce
const TAG_BYTES = 16; // GCM auth tag
const INFO = "agape-answers-v1"; // HKDF context/label; bump to rotate scheme

// Master secret for key derivation. MUST be set in production (e.g. Firebase
// config / env). The dev fallback keeps the emulator working but is NOT secret;
// never ship it. Rotating it invalidates all previously issued keys.
function masterSecret(): Buffer {
  const s = process.env.ANSWER_MASTER_SECRET;
  if (s && s.length >= 16) return Buffer.from(s, "utf8");
  if (process.env.NODE_ENV === "production") {
    throw new Error("ANSWER_MASTER_SECRET must be set in production");
  }
  return Buffer.from("dev-only-insecure-answer-master-secret", "utf8");
}

// HKDF-SHA256(master, salt=uid, info) -> 32-byte per-user key. Deterministic, so
// the server never stores keys; it re-derives on demand.
export function deriveAnswerKey(uid: string): Buffer {
  const derived = crypto.hkdfSync(
    "sha256",
    masterSecret(),
    Buffer.from(uid, "utf8"),
    Buffer.from(INFO, "utf8"),
    KEY_BYTES,
  );
  return Buffer.from(derived);
}

// The per-user key as base64, handed to the authenticated client (over TLS) to
// store in device secure storage.
export function answerKeyBase64(uid: string): string {
  return deriveAnswerKey(uid).toString("base64");
}

// Encrypts one answer payload with the user's key. Returns the base64 token.
export function encryptAnswer(key: Buffer, plaintext: string): string {
  const iv = crypto.randomBytes(IV_BYTES);
  const cipher = crypto.createCipheriv("aes-256-gcm", key, iv);
  const ct = Buffer.concat([cipher.update(plaintext, "utf8"), cipher.final()]);
  const tag = cipher.getAuthTag();
  return Buffer.concat([iv, ct, tag]).toString("base64");
}

// Decrypts a token (used by tests / server-side verification). Throws on a bad
// tag (tamper or wrong key).
export function decryptAnswer(key: Buffer, token: string): string {
  const raw = Buffer.from(token, "base64");
  const iv = raw.subarray(0, IV_BYTES);
  const tag = raw.subarray(raw.length - TAG_BYTES);
  const ct = raw.subarray(IV_BYTES, raw.length - TAG_BYTES);
  const decipher = crypto.createDecipheriv("aes-256-gcm", key, iv);
  decipher.setAuthTag(tag);
  return Buffer.concat([decipher.update(ct), decipher.final()]).toString("utf8");
}

// Encrypts an answer {word, definition} into the wire form {length, enc}. The
// length stays in the clear because the board renders blanks from it.
export function encryptAnswerFields(
  key: Buffer,
  answer: {word: string; length: number; definition: string | null},
): {length: number; enc: string} {
  const payload = JSON.stringify({w: answer.word, d: answer.definition});
  return {length: answer.length, enc: encryptAnswer(key, payload)};
}
