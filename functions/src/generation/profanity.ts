import * as fs from "fs";
import {normalizeWord} from "./word_data";

/**
 * Loads a newline-delimited blocklist of words to exclude from generation
 * (anchors and answers). Blank lines and `#` comments are ignored, entries are
 * normalized to uppercase. A missing file yields an empty set, so the filter is
 * opt-in and never throws the generator.
 */
export function loadBlocklist(path: string): Set<string> {
  let text: string;
  try {
    text = fs.readFileSync(path, "utf8");
  } catch {
    return new Set<string>();
  }
  const out = new Set<string>();
  for (const line of text.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (trimmed === "" || trimmed.startsWith("#")) continue;
    const w = normalizeWord(trimmed);
    if (w) out.add(w);
  }
  return out;
}
