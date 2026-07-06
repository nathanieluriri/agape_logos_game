import {Tier} from "./config";
import {RawPuzzle} from "./generator";

export interface PuzzleAnswer {
  word: string;
  length: number;
  definition: string | null;
}

export interface Puzzle {
  tier: Tier;
  rackSize: number;
  letters: string[];
  letterKey: string;
  anchor: string;
  answers: PuzzleAnswer[];
  answerCount: number;
  genVersion: number;
}

export function attachDefinitions(
  raw: RawPuzzle,
  defs: Map<string, string | null>,
  genVersion: number,
): Puzzle {
  return {
    tier: raw.tier,
    rackSize: raw.rackSize,
    letters: raw.letters,
    letterKey: raw.letterKey,
    anchor: raw.anchor,
    answerCount: raw.answerCount,
    genVersion,
    answers: raw.answers.map((word) => ({
      word,
      length: word.length,
      definition: defs.has(word) ? defs.get(word) ?? null : null,
    })),
  };
}

/**
 * Enforces the rule that EVERY answer carries a definition. Returns the puzzle
 * unchanged when all answers have a non-empty definition; returns null when any
 * answer is missing or blank, signalling the caller to drop the whole puzzle
 * (never ship a rack that hides a common word the player could spell).
 */
export function requireAllDefined(puzzle: Puzzle): Puzzle | null {
  const allDefined = puzzle.answers.every(
    (a) => a.definition != null && a.definition.trim().length > 0,
  );
  return allDefined ? puzzle : null;
}
