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
