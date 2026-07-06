// Builds the bundled offline dictionary that generation reads at runtime:
// parses the WordNet database files (shipped by wordnet-db, a wordpos
// devDependency) into a compact word -> definition JSON. Run once, and again
// only if the WordNet data changes:
//
//   npm run build && node lib/scripts/build_dictionary.js
//
// The output (data/wordnet_defs.json) is committed so generation is fully
// offline and reproducible; no dictionary API, no per-lookup file I/O.

import * as fs from "fs";
import * as path from "path";
import {WORDNET_DEFS_FILE} from "../generation/config";

const DICT_DIR = path.resolve(__dirname, "../../node_modules/wordnet-db/dict");
const DATA_FILES = ["data.noun", "data.verb", "data.adj", "data.adv"];

// A WordNet gloss is "definition; \"example\"; \"example\"". Keep the definition
// part before the first quoted example, trimming a trailing separator.
function cleanDefinition(gloss: string): string {
  return gloss.split("\"")[0].replace(/;\s*$/, "").trim();
}

function main(): void {
  const map: Record<string, string> = {};
  for (const file of DATA_FILES) {
    const text = fs.readFileSync(path.join(DICT_DIR, file), "utf8");
    for (const line of text.split("\n")) {
      if (!/^\d/.test(line)) continue; // skip the license header
      const bar = line.indexOf(" | ");
      if (bar < 0) continue;
      const fields = line.slice(0, bar).trim().split(/\s+/);
      const gloss = cleanDefinition(line.slice(bar + 3));
      if (!gloss) continue;
      // fields: offset lex_filenum ss_type w_cnt(hex) [word lex_id]... then ptrs.
      const wordCount = parseInt(fields[3], 16);
      if (!wordCount) continue;
      for (let i = 0; i < wordCount; i++) {
        const word = fields[4 + i * 2];
        if (!word || !/^[a-zA-Z]+$/.test(word)) continue; // single alpha words only
        const upper = word.toUpperCase();
        if (!(upper in map)) map[upper] = gloss; // first (usually primary) sense
      }
    }
  }
  fs.writeFileSync(WORDNET_DEFS_FILE, JSON.stringify(map, null, 0));
  // eslint-disable-next-line no-console
  console.log("build_dictionary: wrote", Object.keys(map).length, "words to", WORDNET_DEFS_FILE);
}

main();
