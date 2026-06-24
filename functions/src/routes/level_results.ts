import {Response, Router} from "express";
import {FieldValue} from "firebase-admin/firestore";
import {db} from "../firebase";
import {AuthedRequest, requireAuth} from "../middleware/auth";

export const levelResultsRouter = Router();

// POST /levels/:levelId/result
levelResultsRouter.post(
  "/levels/:levelId/result",
  requireAuth,
  async (req: AuthedRequest, res: Response): Promise<void> => {
    const idempotencyKey = req.header("idempotency-key");
    if (!idempotencyKey) {
      res.status(400).json({error: "missing idempotency-key header"});
      return;
    }
    if (
      idempotencyKey.trim() === "" ||
      idempotencyKey.includes("/") ||
      Buffer.byteLength(idempotencyKey, "utf8") > 1500
    ) {
      res.status(400).json({error: "invalid idempotency-key"});
      return;
    }

    const levelId = Number(req.params.levelId);
    const body = (req.body ?? {}) as {score?: unknown; completedAt?: unknown};
    if (
      !Number.isInteger(levelId) ||
      !Number.isInteger(body.score) ||
      !Number.isInteger(body.completedAt)
    ) {
      res
        .status(400)
        .json({error: "levelId, score, completedAt must be integers"});
      return;
    }

    try {
      await db
        .collection("users").doc(req.uid as string)
        .collection("levelResults").doc(idempotencyKey)
        .set({
          levelId,
          score: body.score,
          completedAt: body.completedAt,
          uid: req.uid,
          syncedAt: FieldValue.serverTimestamp(),
        });
    } catch {
      res.status(500).json({error: "internal error"});
      return;
    }

    res.status(200).json({ok: true});
  },
);
