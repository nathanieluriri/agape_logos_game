import {z} from "zod";

export const RewardStatusSchema = z.object({
  unlocked: z.boolean(),
  minLevel: z.number().int(),
  level: z.number().int(),
  coins: z.object({
    amount: z.number().int(),
    claimable: z.boolean(),
    nextClaimInMs: z.number().int(),
  }),
  powerup: z.object({
    claimable: z.boolean(),
    nextClaimInMs: z.number().int(),
  }),
});

export const ClaimCoinsResponseSchema = z.object({
  claimed: z.number().int(),
  coins: z.number().int(),
  nextClaimInMs: z.number().int(),
});

export const ClaimPowerupResponseSchema = z.object({
  granted: z.string(),
  inventory: z.record(z.number().int()),
  nextClaimInMs: z.number().int(),
});
