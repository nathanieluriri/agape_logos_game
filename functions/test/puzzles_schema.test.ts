import {describe, test, expect} from "@jest/globals";
import {
  DrawBodySchema,
  DrawHeadersSchema,
  AssignedQuerySchema,
  PuzzleResultParamsSchema,
  PuzzleResultBodySchema,
} from "../src/schemas/puzzles";

describe("DrawBodySchema", () => {
  test("accepts per-tier non-negative ints with at least one positive", () => {
    expect(DrawBodySchema.safeParse({easy: 20, medium: 40, hard: 40}).success).toBe(true);
    expect(DrawBodySchema.safeParse({expert: 5}).success).toBe(true);
  });
  test("rejects all-zero / empty and negative / non-integer", () => {
    expect(DrawBodySchema.safeParse({}).success).toBe(false);
    expect(DrawBodySchema.safeParse({easy: 0, medium: 0}).success).toBe(false);
    expect(DrawBodySchema.safeParse({easy: -1}).success).toBe(false);
    expect(DrawBodySchema.safeParse({easy: 1.5}).success).toBe(false);
  });
});

describe("DrawHeadersSchema", () => {
  test("requires a slash-free non-empty key", () => {
    expect(DrawHeadersSchema.safeParse({"idempotency-key": "abc"}).success).toBe(true);
    expect(DrawHeadersSchema.safeParse({"idempotency-key": "a/b"}).success).toBe(false);
    expect(DrawHeadersSchema.safeParse({"idempotency-key": ""}).success).toBe(false);
  });
});

describe("AssignedQuerySchema", () => {
  test("defaults to incomplete and rejects unknown status", () => {
    expect(AssignedQuerySchema.parse({}).status).toBe("incomplete");
    expect(AssignedQuerySchema.parse({status: "all"}).status).toBe("all");
    expect(AssignedQuerySchema.safeParse({status: "weird"}).success).toBe(false);
    expect(AssignedQuerySchema.parse({status: "completed"}).status).toBe("completed");
  });
});

describe("PuzzleResult schemas", () => {
  test("puzzleId must be uppercase letters", () => {
    expect(PuzzleResultParamsSchema.safeParse({puzzleId: "NOW"}).success).toBe(true);
    expect(PuzzleResultParamsSchema.safeParse({puzzleId: "now"}).success).toBe(false);
    expect(PuzzleResultParamsSchema.safeParse({puzzleId: "N0W"}).success).toBe(false);
  });
  test("body requires integer score and completedAt", () => {
    expect(PuzzleResultBodySchema.safeParse({score: 10, completedAt: 5}).success).toBe(true);
    expect(PuzzleResultBodySchema.safeParse({score: "x", completedAt: 5}).success).toBe(false);
  });
});
