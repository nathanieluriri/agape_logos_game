import {Response, Router} from "express";
import {AuthedRequest, requireAuth} from "../middleware/auth";
import {asyncHandler} from "../middleware/error";
import {getDictionary} from "../services/dictionary_service";

export const dictionaryRouter = Router();

// GET /me/dictionary - the caller's solved words (with definitions) across every
// completed puzzle. Survives reinstall and is consistent cross-device because it
// is derived from the user's server-side assignment history, not local cache.
dictionaryRouter.get(
  "/me/dictionary",
  requireAuth,
  asyncHandler<AuthedRequest>(async (req, res: Response) => {
    const result = await getDictionary(req.uid as string);
    res.status(200).json(result);
  }),
);
