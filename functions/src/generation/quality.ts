import {TierConfig} from "./config";

export function meetsAnswerGate(answerCount: number, tier: TierConfig): boolean {
  if (answerCount < tier.minAnswers) return false;
  if (tier.maxAnswers != null && answerCount > tier.maxAnswers) return false;
  return true;
}
