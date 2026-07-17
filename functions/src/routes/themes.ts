import {Response, Router} from "express";
import {AuthedRequest, requireAuth} from "../middleware/auth";
import {asyncHandler} from "../middleware/error";
import {listThemes} from "../services/theme_service";

export const themesRouter = Router();

// GET /themes?q= - searchable theme list for the match settings picker. Empty
// when the theme system is not seeded.
themesRouter.get(
  "/themes",
  requireAuth,
  asyncHandler<AuthedRequest>(async (req, res: Response) => {
    const q = typeof req.query.q === "string" ? req.query.q : undefined;
    res.status(200).json({themes: await listThemes(q)});
  }),
);
