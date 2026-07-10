import {Response, Router} from "express";
import {AuthedRequest, requireAuth} from "../middleware/auth";
import {asyncHandler} from "../middleware/error";
import {validate, ValidatedRequest} from "../middleware/validate";
import {
  FriendRequestBody,
  FriendRequestBodySchema,
  FriendRespondBody,
  FriendRespondBodySchema,
  IdempotencyHeaderSchema,
  MatchHistoryQuerySchema,
  PrivacyBody,
  PrivacyBodySchema,
  UserSearchQuerySchema,
} from "../schemas/social";
import {
  getMatchHistory,
  getPublicProfile,
  listFriends,
  respondFriendRequest,
  searchUsers,
  sendFriendRequest,
  setPrivacy,
} from "../services/social_service";

export const socialRouter = Router();

// PUT /me/privacy - make the profile searchable + publicly viewable, or not.
socialRouter.put(
  "/me/privacy",
  requireAuth,
  validate({headers: IdempotencyHeaderSchema, body: PrivacyBodySchema}),
  asyncHandler<AuthedRequest & ValidatedRequest>(async (req, res: Response) => {
    const body = req.valid?.body as PrivacyBody;
    await setPrivacy(req.uid as string, body.public);
    res.status(200).json({ok: true});
  }),
);

// GET /users/search?q= - prefix search over PUBLIC profiles only. Query is
// validated inline (the shared validate middleware covers params/body/headers).
socialRouter.get(
  "/users/search",
  requireAuth,
  asyncHandler<AuthedRequest>(async (req, res: Response) => {
    const parsed = UserSearchQuerySchema.safeParse(req.query);
    if (!parsed.success) {
      res.status(400).json({error: "validation failed", issues: parsed.error.issues});
      return;
    }
    const users = await searchUsers(parsed.data.q, parsed.data.limit);
    res.status(200).json({users});
  }),
);

// GET /users/:uid/public - one user's public projection (+ recent matches).
socialRouter.get(
  "/users/:uid/public",
  requireAuth,
  asyncHandler<AuthedRequest>(async (req, res: Response) => {
    const result = await getPublicProfile(req.uid as string, req.params.uid);
    if (!result) {
      res.status(403).json({error: "profile is private"});
      return;
    }
    res.status(200).json(result);
  }),
);

// POST /friends/request - send a friend request by uid or @handle.
socialRouter.post(
  "/friends/request",
  requireAuth,
  validate({headers: IdempotencyHeaderSchema, body: FriendRequestBodySchema}),
  asyncHandler<AuthedRequest & ValidatedRequest>(async (req, res: Response) => {
    const body = req.valid?.body as FriendRequestBody;
    const result = await sendFriendRequest(req.uid as string, {toUid: body.toUid, handle: body.handle});
    if (!result.ok) {
      res.status(result.reason === "self" ? 400 : 404).json({error: result.reason});
      return;
    }
    res.status(200).json({ok: true});
  }),
);

// POST /friends/respond - accept (reciprocal friendship) or decline (delete).
socialRouter.post(
  "/friends/respond",
  requireAuth,
  validate({headers: IdempotencyHeaderSchema, body: FriendRespondBodySchema}),
  asyncHandler<AuthedRequest & ValidatedRequest>(async (req, res: Response) => {
    const body = req.valid?.body as FriendRespondBody;
    const result = await respondFriendRequest(req.uid as string, body.fromUid, body.accept);
    if (!result.ok) {
      res.status(404).json({error: result.reason});
      return;
    }
    res.status(200).json({ok: true});
  }),
);

// GET /friends - accepted friends + incoming pending requests.
socialRouter.get(
  "/friends",
  requireAuth,
  asyncHandler<AuthedRequest>(async (req, res: Response) => {
    res.status(200).json(await listFriends(req.uid as string));
  }),
);

// GET /me/matches - the caller's match history (query validated inline).
socialRouter.get(
  "/me/matches",
  requireAuth,
  asyncHandler<AuthedRequest>(async (req, res: Response) => {
    const parsed = MatchHistoryQuerySchema.safeParse(req.query);
    if (!parsed.success) {
      res.status(400).json({error: "validation failed", issues: parsed.error.issues});
      return;
    }
    const history = await getMatchHistory(req.uid as string, parsed.data.limit);
    res.status(200).json({history});
  }),
);
