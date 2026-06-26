import {Rng, shuffle} from "../generation/random";

export interface SelectResult {
  chosen: string[];
  shortfall: number;
}

// Pick up to n ids from candidateIds not in assignedIds, in shuffled order.
// shortfall is how many short of n we fell (pool exhausted for this user).
export function selectUnseen(
  candidateIds: string[],
  assignedIds: Set<string>,
  n: number,
  rng: Rng,
): SelectResult {
  const unseen = candidateIds.filter((id) => !assignedIds.has(id));
  const chosen = shuffle(unseen, rng).slice(0, n);
  return {chosen, shortfall: Math.max(0, n - chosen.length)};
}
