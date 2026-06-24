import {Response, Router} from "express";
import {AuthedRequest, requireAuth} from "../middleware/auth";
import {asyncHandler} from "../middleware/error";
import {validate, ValidatedRequest} from "../middleware/validate";
import {
  LevelParamsSchema,
  LevelResultBody,
  LevelResultBodySchema,
  LevelResultHeadersSchema,
} from "../schemas/level_results";
import {saveLevelResult} from "../services/level_results_service";

export const levelResultsRouter = Router();

// POST /levels/:levelId/result - authenticated, idempotent level-result write.
levelResultsRouter.post(
  "/levels/:levelId/result",
  requireAuth,
  validate({
    params: LevelParamsSchema,
    headers: LevelResultHeadersSchema,
    body: LevelResultBodySchema,
  }),
  asyncHandler<AuthedRequest & ValidatedRequest>(async (req, res: Response) => {
    const {levelId} = req.valid?.params as {levelId: number};
    const headers = req.valid?.headers as {"idempotency-key": string};
    const body = req.valid?.body as LevelResultBody;
    await saveLevelResult(req.uid as string, headers["idempotency-key"], levelId, body);
    res.status(200).json({ok: true});
  }),
);
