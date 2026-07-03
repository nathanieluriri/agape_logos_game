import {describe, test, expect} from "@jest/globals";
import {
  answerKeyBase64,
  decryptAnswer,
  deriveAnswerKey,
  encryptAnswer,
  encryptAnswerFields,
} from "../src/crypto/answer_cipher";

describe("answer_cipher", () => {
  test("key derivation is deterministic per uid and unique across uids", () => {
    expect(deriveAnswerKey("u1").equals(deriveAnswerKey("u1"))).toBe(true);
    expect(deriveAnswerKey("u1").equals(deriveAnswerKey("u2"))).toBe(false);
    expect(deriveAnswerKey("u1").length).toBe(32);
    expect(answerKeyBase64("u1")).toBe(deriveAnswerKey("u1").toString("base64"));
  });

  test("encrypt/decrypt round-trips and hides the plaintext", () => {
    const key = deriveAnswerKey("u1");
    const token = encryptAnswer(key, "hello");
    expect(token).not.toContain("hello");
    expect(decryptAnswer(key, token)).toBe("hello");
  });

  test("a different user's key cannot decrypt (auth tag fails)", () => {
    const token = encryptAnswer(deriveAnswerKey("u1"), "secret");
    expect(() => decryptAnswer(deriveAnswerKey("u2"), token)).toThrow();
  });

  test("random IV makes each token unique", () => {
    const key = deriveAnswerKey("u1");
    expect(encryptAnswer(key, "same")).not.toBe(encryptAnswer(key, "same"));
  });

  test("encryptAnswerFields keeps length in the clear and hides the word", () => {
    const key = deriveAnswerKey("u1");
    const wire = encryptAnswerFields(key, {
      word: "POND",
      length: 4,
      definition: "a pool",
    });
    expect(wire.length).toBe(4);
    expect(wire.enc).not.toContain("POND");
    expect(JSON.parse(decryptAnswer(key, wire.enc))).toEqual({w: "POND", d: "a pool"});
  });
});
