import {TierConfig} from "./config";

export function meetsAnswerGate(answerCount: number, tier: TierConfig): boolean {
  return answerCount >= tier.minAnswers;
}
