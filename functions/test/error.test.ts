import express from "express";
import request from "supertest";
import {describe, test, expect} from "@jest/globals";
import {asyncHandler, errorHandler, notFound} from "../src/middleware/error";

function buildApp(): express.Express {
  const app = express();
  app.get("/boom", asyncHandler(async () => {
    throw new Error("kaboom");
  }));
  app.use(notFound);
  app.use(errorHandler);
  return app;
}

describe("error middleware", () => {
  test("asyncHandler forwards throws to errorHandler -> 500", async () => {
    const res = await request(buildApp()).get("/boom");
    expect(res.status).toBe(500);
    expect(res.body).toEqual({error: "internal error"});
  });

  test("notFound -> 404 for an unmatched route", async () => {
    const res = await request(buildApp()).get("/nope");
    expect(res.status).toBe(404);
    expect(res.body).toEqual({error: "not found"});
  });
});
