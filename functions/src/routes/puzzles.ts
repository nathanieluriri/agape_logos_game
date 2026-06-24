import {Response, Router} from "express";
import {AuthedRequest, requireAuth} from "../middleware/auth";
import {asyncHandler} from "../middleware/error";
import {validate, ValidatedRequest} from "../middleware/validate";
import {
  AssignedQuerySchema,
  DrawBody,
  DrawBodySchema,
  DrawHeadersSchema,
  PuzzleResultBody,
  PuzzleResultBodySchema,
  PuzzleResultHeadersSchema,
  PuzzleResultParamsSchema,
} from "../schemas/puzzles";
import {draw, getAssigned} from "../services/assignment_service";
import {savePuzzleResult} from "../services/puzzle_result_service";

export const puzzlesRouter = Router();

// GET /puzzles/assigned?status=incomplete|all - recover assigned puzzles by reference.
puzzlesRouter.get(
  "/puzzles/assigned",
  requireAuth,
  asyncHandler<AuthedRequest>(async (req, res: Response) => {
    const parsed = AssignedQuerySchema.safeParse(req.query);
    if (!parsed.success) {
      res.status(400).json({error: "validation failed", issues: parsed.error.issues});
      return;
    }
    const result = await getAssigned(req.uid as string, parsed.data.status);
    res.status(200).json(result);
  }),
);

// POST /puzzles/draw - assign a batch of unseen puzzles per requested tier.
puzzlesRouter.post(
  "/puzzles/draw",
  requireAuth,
  validate({headers: DrawHeadersSchema, body: DrawBodySchema}),
  asyncHandler<AuthedRequest & ValidatedRequest>(async (req, res: Response) => {
    const headers = req.valid?.headers as {"idempotency-key": string};
    const body = req.valid?.body as DrawBody;
    const result = await draw(req.uid as string, body, headers["idempotency-key"]);
    res.status(200).json(result);
  }),
);

// POST /puzzles/:puzzleId/result - record a solved puzzle and mark it completed.
puzzlesRouter.post(
  "/puzzles/:puzzleId/result",
  requireAuth,
  validate({
    params: PuzzleResultParamsSchema,
    headers: PuzzleResultHeadersSchema,
    body: PuzzleResultBodySchema,
  }),
  asyncHandler<AuthedRequest & ValidatedRequest>(async (req, res: Response) => {
    const {puzzleId} = req.valid?.params as {puzzleId: string};
    const headers = req.valid?.headers as {"idempotency-key": string};
    const body = req.valid?.body as PuzzleResultBody;
    await savePuzzleResult(req.uid as string, headers["idempotency-key"], puzzleId, body);
    res.status(200).json({ok: true});
  }),
);
