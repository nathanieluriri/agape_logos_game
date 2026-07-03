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
 * Enforces the rule that every surfaced word carries a definition. Drops answers
 * whose definition is missing or blank and recomputes answerCount. Returns null
 * when fewer than `minAnswers` defined answers remain, signalling the caller to
 * drop the whole puzzle rather than ship a threadbare board.
 */
export function withDefinedAnswersOnly(
  puzzle: Puzzle,
  minAnswers: number,
): Puzzle | null {
  const answers = puzzle.answers.filter(
    (a) => a.definition != null && a.definition.trim().length > 0,
  );
  if (answers.length < minAnswers) return null;
  if (answers.length === puzzle.answers.length) return puzzle;
  return {...puzzle, answers, answerCount: answers.length};
}
