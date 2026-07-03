import {Response, Router} from "express";
import {AuthedRequest, requireAuth} from "../middleware/auth";
import {asyncHandler} from "../middleware/error";
import {validate, ValidatedRequest} from "../middleware/validate";
import {PurchaseBody, PurchaseBodySchema, PurchaseHeadersSchema} from "../schemas/store";
import {STORE_ITEMS} from "../store/catalog";
import {getInventory, purchase} from "../services/store_service";

export const storeRouter = Router();

// GET /store - the full catalog (hints + powerups). Powerups are inert for now
// (multiplayer will consume them); the client renders them as buyable.
storeRouter.get(
  "/store",
  requireAuth,
  asyncHandler<AuthedRequest>(async (_req, res: Response) => {
    res.status(200).json({items: STORE_ITEMS});
  }),
);

// GET /me/inventory - the caller's owned consumables.
storeRouter.get(
  "/me/inventory",
  requireAuth,
  asyncHandler<AuthedRequest>(async (req, res: Response) => {
    res.status(200).json({inventory: await getInventory(req.uid as string)});
  }),
);

// POST /store/purchase - spend coins on an item. Idempotent via idempotency-key.
// 200 on success, 400 for an unknown item, 402 when the wallet is short.
storeRouter.post(
  "/store/purchase",
  requireAuth,
  validate({headers: PurchaseHeadersSchema, body: PurchaseBodySchema}),
  asyncHandler<AuthedRequest & ValidatedRequest>(async (req, res: Response) => {
    const headers = req.valid?.headers as {"idempotency-key": string};
    const body = req.valid?.body as PurchaseBody;
    const result = await purchase(
      req.uid as string,
      headers["idempotency-key"],
      body.itemId,
      body.quantity,
    );
    if (!result.ok) {
      if (result.reason === "unknown_item") {
        res.status(400).json({error: "unknown item"});
        return;
      }
      res.status(402).json({
        error: "insufficient coins",
        cost: result.cost,
        coins: result.coins,
      });
      return;
    }
    res.status(200).json({
      coins: result.coins,
      inventory: result.inventory,
      charged: result.charged,
      replay: result.replay,
    });
  }),
);
