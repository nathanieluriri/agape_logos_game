import request from "supertest";
import {createApp} from "../src/app";
import {describe, test, expect} from "@jest/globals";

const app = createApp();

describe("API docs", () => {
  test("GET /openapi.json exposes paths and bearerAuth", async () => {
    const res = await request(app).get("/openapi.json");
    expect(res.status).toBe(200);
    expect(res.body.openapi).toBe("3.0.0");
    expect(res.body.paths["/me"]).toBeDefined();
    expect(res.body.paths["/me/dictionary"]).toBeDefined();
    expect(res.body.paths["/levels/{levelId}/result"]).toBeDefined();
    expect(res.body.components.securitySchemes.bearerAuth).toBeDefined();
  });

  test("GET /docs returns the Scalar HTML page", async () => {
    const res = await request(app).get("/docs");
    expect(res.status).toBe(200);
    expect(res.headers["content-type"]).toContain("text/html");
    expect(res.text).toContain("api-reference");
  });
});
