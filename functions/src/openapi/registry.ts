import {OpenAPIRegistry, extendZodWithOpenApi} from "@asteasolutions/zod-to-openapi";
import {z} from "zod";

// Adds .openapi() to zod and lets the generator read schema metadata. Must run
// before the document is generated.
extendZodWithOpenApi(z);

export const registry = new OpenAPIRegistry();

registry.registerComponent("securitySchemes", "bearerAuth", {
  type: "http",
  scheme: "bearer",
  bearerFormat: "JWT",
});
