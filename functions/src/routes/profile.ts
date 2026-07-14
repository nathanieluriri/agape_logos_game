import {Response, Router} from "express";
import {AuthedRequest, requireAuth} from "../middleware/auth";
import {asyncHandler} from "../middleware/error";
import {validate, ValidatedRequest} from "../middleware/validate";
import {HandleBodySchema, ProfilePatch, ProfileUpdateSchema} from "../schemas/profile";
import {IdempotencyHeadersSchema} from "../schemas/matches";
import {getCoins, getOrCreateProfile, updateProfile} from "../services/profile_service";
import {setHandle} from "../services/handle_service";
import {answerKeyBase64} from "../crypto/answer_cipher";

export const profileRouter = Router();

type Authed = AuthedRequest & ValidatedRequest;

// GET /me - returns the caller's profile, auto-creating it on first read.
profileRouter.get(
  "/me",
  requireAuth,
  asyncHandler<AuthedRequest>(async (req, res: Response) => {
    const profile = await getOrCreateProfile(req.uid as string, {isGuest: req.isGuest});
    res.status(200).json(profile);
  }),
);

// GET /me/coins - returns just the caller's coin balance. A lighter read for
// screens that only need the wallet (e.g. the coin pill) without the full
// profile payload. Provisions the profile on first read like GET /me.
profileRouter.get(
  "/me/coins",
  requireAuth,
  asyncHandler<AuthedRequest>(async (req, res: Response) => {
    const coins = await getCoins(req.uid as string);
    res.status(200).json(coins);
  }),
);

// GET /me/answer-key - the caller's per-user key (base64) for decrypting puzzle
// answers on-device. Delivered only to the authenticated owner over TLS; the
// client stores it in device secure storage, not the local DB.
profileRouter.get(
  "/me/answer-key",
  requireAuth,
  asyncHandler<AuthedRequest>(async (req, res: Response) => {
    res.status(200).json({key: answerKeyBase64(req.uid as string)});
  }),
);

// PUT /me - updates editable fields and returns the full updated profile.
profileRouter.put(
  "/me",
  requireAuth,
  validate({body: ProfileUpdateSchema}),
  asyncHandler<AuthedRequest & ValidatedRequest>(async (req, res: Response) => {
    const patch = (req.valid?.body ?? {}) as ProfilePatch;
    const profile = await updateProfile(req.uid as string, patch);
    res.status(200).json(profile);
  }),
);

// PUT /me/handle - claim a new unique handle. 409 when someone else holds it.
profileRouter.put(
  "/me/handle",
  requireAuth,
  validate({headers: IdempotencyHeadersSchema, body: HandleBodySchema}),
  asyncHandler<Authed>(async (req, res: Response) => {
    const {handle} = req.valid?.body as {handle: string};
    const out = await setHandle(req.uid as string, handle);
    if (!out.ok) {
      res.status(out.reason === "taken" ? 409 : 400).json({error: out.reason});
      return;
    }
    res.status(200).json({handle: out.handle});
  }),
);
