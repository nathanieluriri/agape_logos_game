import cors from "cors";
import express from "express";
import {levelResultsRouter} from "./routes/level_results";
import {puzzlesRouter} from "./routes/puzzles";
import {profileRouter} from "./routes/profile";
import {storeRouter} from "./routes/store";
import {rewardsRouter} from "./routes/rewards";
import {errorHandler, notFound} from "./middleware/error";
import {buildOpenApiDocument} from "./openapi/document";
import {docsHtml} from "./openapi/docs_page";

// Builds the Express app: CORS, JSON parsing, routers, the docs surfaces, then
// the 404 and 500 fallbacks (registered last so they run after everything).
export function createApp(): express.Express {
  const app = express();
  app.use(cors({origin: true}));
  app.use(express.json());
  app.use(profileRouter);
  app.use(levelResultsRouter);
  app.use(puzzlesRouter);
  app.use(storeRouter);
  app.use(rewardsRouter);
  app.get("/openapi.json", (_req, res) => {
    res.json(buildOpenApiDocument());
  });
  app.get("/docs", (_req, res) => {
    res.type("html").send(docsHtml());
  });
  app.use(notFound);
  app.use(errorHandler);
  return app;
}
