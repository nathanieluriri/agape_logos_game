import {Response, Router} from "express";
import {AuthedRequest, requireAuth} from "../middleware/auth";
import {asyncHandler} from "../middleware/error";
import {validate, ValidatedRequest} from "../middleware/validate";
import {DrawBody, DrawBodySchema, DrawHeadersSchema} from "../schemas/puzzles";
import {draw} from "../services/assignment_service";

export const puzzlesRouter = Router();

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
