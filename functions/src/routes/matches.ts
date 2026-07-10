import {Response, Router} from "express";
import {AuthedRequest, requireAuth} from "../middleware/auth";
import {asyncHandler} from "../middleware/error";
import {validate, ValidatedRequest} from "../middleware/validate";
import {
  CreateMatchBodySchema,
  IdempotencyHeadersSchema,
  JoinMatchBodySchema,
  MatchParamsSchema,
  MatchSettingsSchema,
  PowerupBodySchema,
  ReadyBodySchema,
  StartBodySchema,
  SubmitBodySchema,
} from "../schemas/matches";
import type {PowerupKind} from "../schemas/matches";
import {createMatch, joinMatch, leaveMatch, setReady, startMatch} from "../services/match_service";
import {submitWord} from "../services/match_submit_service";
import {firePowerup} from "../services/match_powerup_service";
import {settleMatch} from "../services/match_finalize";

export const matchesRouter = Router();

type Authed = AuthedRequest & ValidatedRequest;

// POST /matches - create a lobby (creator only), draw the creator rack. 201.
matchesRouter.post(
  "/matches",
  requireAuth,
  validate({headers: IdempotencyHeadersSchema, body: CreateMatchBodySchema}),
  asyncHandler<Authed>(async (req, res: Response) => {
    const headers = req.valid?.headers as {"idempotency-key": string};
    const body = req.valid?.body as {settings?: unknown};
    const settings = MatchSettingsSchema.parse(body.settings ?? {});
    const out = await createMatch(
      req.uid as string,
      req.isGuest ?? false,
      headers["idempotency-key"],
      settings,
    );
    res.status(201).json(out);
  }),
);

// POST /matches/join - join by code, draw the joiner rack. 404 unknown/closed.
matchesRouter.post(
  "/matches/join",
  requireAuth,
  validate({body: JoinMatchBodySchema}),
  asyncHandler<Authed>(async (req, res: Response) => {
    const body = req.valid?.body as {code: string};
    const out = await joinMatch(req.uid as string, req.isGuest ?? false, body.code);
    res.status(200).json(out);
  }),
);

// POST /matches/:id/ready - toggle ready; both ready -> countdown.
matchesRouter.post(
  "/matches/:id/ready",
  requireAuth,
  validate({params: MatchParamsSchema, body: ReadyBodySchema}),
  asyncHandler<Authed>(async (req, res: Response) => {
    const {id} = req.valid?.params as {id: string};
    const {ready} = req.valid?.body as {ready: boolean};
    res.status(200).json(await setReady(req.uid as string, id, ready));
  }),
);

// POST /matches/:id/start - creator force-start.
matchesRouter.post(
  "/matches/:id/start",
  requireAuth,
  validate({params: MatchParamsSchema, body: StartBodySchema}),
  asyncHandler<Authed>(async (req, res: Response) => {
    const {id} = req.valid?.params as {id: string};
    res.status(200).json(await startMatch(req.uid as string, id));
  }),
);

// POST /matches/:id/submit - validate a word vs the caller's rack; score it.
matchesRouter.post(
  "/matches/:id/submit",
  requireAuth,
  validate({params: MatchParamsSchema, body: SubmitBodySchema}),
  asyncHandler<Authed>(async (req, res: Response) => {
    const {id} = req.valid?.params as {id: string};
    const {word} = req.valid?.body as {word: string};
    res.status(200).json(await submitWord(req.uid as string, id, word));
  }),
);

// POST /matches/:id/powerup - spend inventory, write an event. 402 if none owned.
// The idempotency-key IS the event id (plan 10 section 8.7).
matchesRouter.post(
  "/matches/:id/powerup",
  requireAuth,
  validate({params: MatchParamsSchema, headers: IdempotencyHeadersSchema, body: PowerupBodySchema}),
  asyncHandler<Authed>(async (req, res: Response) => {
    const {id} = req.valid?.params as {id: string};
    const headers = req.valid?.headers as {"idempotency-key": string};
    const {kind} = req.valid?.body as {kind: PowerupKind};
    res.status(200).json(await firePowerup(req.uid as string, id, kind, headers["idempotency-key"]));
  }),
);

// POST /matches/:id/leave - leave/cancel; finalizes if in progress.
matchesRouter.post(
  "/matches/:id/leave",
  requireAuth,
  validate({params: MatchParamsSchema}),
  asyncHandler<Authed>(async (req, res: Response) => {
    const {id} = req.valid?.params as {id: string};
    res.status(200).json(await leaveMatch(req.uid as string, id));
  }),
);

// GET /matches/:id - optional (clients mostly use listeners). Settles the clock
// and returns the doc if the caller is a participant.
matchesRouter.get(
  "/matches/:id",
  requireAuth,
  validate({params: MatchParamsSchema}),
  asyncHandler<Authed>(async (req, res: Response) => {
    const {id} = req.valid?.params as {id: string};
    const m = await settleMatch(id);
    if (!m) {
      res.status(404).json({error: "not found"});
      return;
    }
    if (!m.participants.includes(req.uid as string)) {
      res.status(403).json({error: "not a participant"});
      return;
    }
    res.status(200).json(m);
  }),
);
