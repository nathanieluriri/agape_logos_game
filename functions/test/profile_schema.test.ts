import {describe, test, expect} from "@jest/globals";
import {ProfileUpdateSchema} from "../src/schemas/profile";

describe("ProfileUpdateSchema", () => {
  test("accepts a partial valid patch", () => {
    expect(ProfileUpdateSchema.safeParse({displayName: "Neo"}).success).toBe(true);
  });

  test("rejects displayName over 30 chars", () => {
    expect(ProfileUpdateSchema.safeParse({displayName: "x".repeat(31)}).success).toBe(false);
  });

  test("rejects unknown / read-only keys (strict)", () => {
    expect(ProfileUpdateSchema.safeParse({totalScore: 999}).success).toBe(false);
  });

  test("rejects a non-boolean soundEnabled", () => {
    expect(ProfileUpdateSchema.safeParse({soundEnabled: "yes"}).success).toBe(false);
  });

  test("rejects an unknown avatarId", () => {
    expect(ProfileUpdateSchema.safeParse({avatarId: "avatar_99"}).success).toBe(false);
  });
});
