import cors from "cors";
import express from "express";

// Builds the Express app. Routes are mounted in Task 2.
export function createApp(): express.Express {
  const app = express();
  app.use(cors({origin: true}));
  app.use(express.json());
  return app;
}
