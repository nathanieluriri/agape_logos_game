import cors from "cors";
import express from "express";
import {levelResultsRouter} from "./routes/level_results";
import {errorHandler, notFound} from "./middleware/error";

// Builds the Express app with CORS, JSON parsing, routes, then the 404 and
// 500 fallbacks (registered last so they run after all routers).
export function createApp(): express.Express {
  const app = express();
  app.use(cors({origin: true}));
  app.use(express.json());
  app.use(levelResultsRouter);
  app.use(notFound);
  app.use(errorHandler);
  return app;
}
