import {Response, Router} from "express";
import {AuthedRequest, requireAuth} from "../middleware/auth";
import {asyncHandler} from "../middleware/error";
import {claimCoins, claimPowerup, getRewardStatus} from "../services/rewards_service";

export const rewardsRouter = Router();

// GET /rewards - claim eligibility, computed lazily from timestamps (no writes).
rewardsRouter.get(
  "/rewards",
  requireAuth,
  asyncHandler<AuthedRequest>(async (req, res: Response) => {
    res.status(200).json(await getRewardStatus(req.uid as string));
  }),
);

// POST /rewards/claim-coins - claim the 72h coin reward.
rewardsRouter.post(
  "/rewards/claim-coins",
  requireAuth,
  asyncHandler<AuthedRequest>(async (req, res: Response) => {
    const result = await claimCoins(req.uid as string);
    if (!result.ok) {
      if (result.reason === "locked") {
        res.status(403).json({error: "locked", minLevel: result.minLevel});
        return;
      }
      res.status(409).json({error: "on cooldown", nextClaimInMs: result.nextClaimInMs});
      return;
    }
    res.status(200).json({
      claimed: result.claimed,
      coins: result.coins,
      nextClaimInMs: result.nextClaimInMs,
    });
  }),
);

// POST /rewards/claim-powerup - claim the weekly shuffle-bag powerup.
rewardsRouter.post(
  "/rewards/claim-powerup",
  requireAuth,
  asyncHandler<AuthedRequest>(async (req, res: Response) => {
    const result = await claimPowerup(req.uid as string);
    if (!result.ok) {
      if (result.reason === "locked") {
        res.status(403).json({error: "locked", minLevel: result.minLevel});
        return;
      }
      res.status(409).json({error: "on cooldown", nextClaimInMs: result.nextClaimInMs});
      return;
    }
    res.status(200).json({
      granted: result.granted,
      inventory: result.inventory,
      nextClaimInMs: result.nextClaimInMs,
    });
  }),
);
