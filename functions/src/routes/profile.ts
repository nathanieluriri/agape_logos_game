import {Response, Router} from "express";
import {AuthedRequest, requireAuth} from "../middleware/auth";
import {asyncHandler} from "../middleware/error";
import {validate, ValidatedRequest} from "../middleware/validate";
import {ProfilePatch, ProfileUpdateSchema} from "../schemas/profile";
import {getOrCreateProfile, updateProfile} from "../services/profile_service";

export const profileRouter = Router();

// GET /me - returns the caller's profile, auto-creating it on first read.
profileRouter.get(
  "/me",
  requireAuth,
  asyncHandler<AuthedRequest>(async (req, res: Response) => {
    const profile = await getOrCreateProfile(req.uid as string);
    res.status(200).json(profile);
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
