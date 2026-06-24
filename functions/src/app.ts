import cors from "cors";
import express from "express";
import {levelResultsRouter} from "./routes/level_results";

// Builds the Express app with CORS, JSON parsing, and the mutation routes.
export function createApp(): express.Express {
  const app = express();
  app.use(cors({origin: true}));
  app.use(express.json());
  app.use(levelResultsRouter);
  return app;
}
