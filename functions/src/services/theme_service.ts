import {db} from "../firebase";
import type {Tier} from "../generation/config";

export interface ThemeSummary {
  id: string;
  name: string;
}

// Lists themes, optional case-insensitive name-prefix filter. Empty collection
// (theme system off) -> []. Bounded result set.
export async function listThemes(q?: string): Promise<ThemeSummary[]> {
  const snap = await db.collection("themes").limit(100).get();
  const all = snap.docs.map((d) => {
    const data = d.data() as {name?: string};
    return {id: d.id, name: data.name ?? d.id};
  });
  if (!q) return all;
  const needle = q.trim().toLowerCase();
  return all.filter((t) => t.name.toLowerCase().includes(needle));
}

// A themed puzzle id for [tier], excluding [exclude]. Returns null when the theme
// has no tagged puzzle at this tier (caller falls back to the untethered draw).
export async function themedPuzzleId(
  themeId: string,
  tier: Tier,
  exclude: Set<string>,
): Promise<string | null> {
  const snap = await db
    .collection("puzzles")
    .where("themes", "array-contains", themeId)
    .where("tier", "==", tier)
    .limit(50)
    .select()
    .get();
  const ids = snap.docs.map((d) => d.id).filter((id) => !exclude.has(id));
  if (ids.length === 0) return null;
  return ids[Math.floor(Math.random() * ids.length)];
}
