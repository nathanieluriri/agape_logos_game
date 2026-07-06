// Minimal type declaration for the `wordpos` package (no bundled types).
// wordpos bundles the WordNet database and does offline, morphology-aware
// lookups (e.g. CATS -> cat). Only the surface we use is declared here.
declare module "wordpos" {
  interface WordPosSynset {
    def?: string;
    synonyms?: string[];
    lemma?: string;
    pos?: string;
  }
  class WordPOS {
    constructor(options?: Record<string, unknown>);
    lookup(word: string): Promise<WordPosSynset[]>;
  }
  export = WordPOS;
}
