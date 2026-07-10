import cors from "cors";
import express from "express";
import {levelResultsRouter} from "./routes/level_results";
import {puzzlesRouter} from "./routes/puzzles";
import {profileRouter} from "./routes/profile";
import {dictionaryRouter} from "./routes/dictionary";
import {socialRouter} from "./routes/social";
import {storeRouter} from "./routes/store";
import {rewardsRouter} from "./routes/rewards";
import {matchesRouter} from "./routes/matches";
import {themesRouter} from "./routes/themes";
import {errorHandler, notFound} from "./middleware/error";
import {buildOpenApiDocument} from "./openapi/document";
import {docsHtml} from "./openapi/docs_page";

// Builds the Express app: CORS, JSON parsing, routers, the docs surfaces, then
// the 404 and 500 fallbacks (registered last so they run after everything).
export function createApp(): express.Express {
  const app = express();
  app.use(cors({origin: true}));
  app.use(express.json());
  // Lightweight reachability probe. The Flutter client points its connectivity
  // checker at this instead of third-party captive-portal URLs (Apple,
  // Cloudflare), which the browser blocks with CORS on Web and which therefore
  // make the app falsely report "offline". Cheap, unauthenticated, no Firestore
  // access. Must return exactly 200 (the checker treats only 200 as reachable)
  // and no-store so repeated HEAD probes are never served from browser cache.
 
  app.get("/health", (_req, res) => {
    res.set("Cache-Control", "no-store");
    res.status(200).json({status: "ok"});
  });
  app.use(profileRouter);
  app.use(socialRouter);
  app.use(dictionaryRouter);
  app.use(levelResultsRouter);
  app.use(puzzlesRouter);
  app.use(storeRouter);
  app.use(rewardsRouter);
  app.use(matchesRouter);
  app.use(themesRouter);
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
