import express from "express";
import request from "supertest";
import {z} from "zod";
import {describe, test, expect} from "@jest/globals";
import {validate, ValidatedRequest} from "../src/middleware/validate";

function appWith(schema: z.ZodTypeAny): express.Express {
  const app = express();
  app.use(express.json());
  app.post("/echo", validate({body: schema}), (req: ValidatedRequest, res) => {
    res.status(200).json(req.valid?.body);
  });
  return app;
}

describe("validate middleware", () => {
  const schema = z.object({n: z.number().int()}).strict();

  test("passes valid body and attaches req.valid", async () => {
    const res = await request(appWith(schema)).post("/echo").send({n: 5});
    expect(res.status).toBe(200);
    expect(res.body).toEqual({n: 5});
  });

  test("400 with issues on invalid body", async () => {
    const res = await request(appWith(schema)).post("/echo").send({n: "x"});
    expect(res.status).toBe(400);
    expect(res.body.error).toBe("validation failed");
    expect(Array.isArray(res.body.issues)).toBe(true);
  });

  test("400 on unknown key (strict schema)", async () => {
    const res = await request(appWith(schema)).post("/echo").send({n: 5, extra: 1});
    expect(res.status).toBe(400);
  });
});
