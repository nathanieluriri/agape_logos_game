import {OpenApiGeneratorV3} from "@asteasolutions/zod-to-openapi";
import {registry} from "./registry";
import "./paths";

// Generates the OpenAPI 3 document from the registry. Importing "./paths"
// above registers every route before generation runs.
export function buildOpenApiDocument() {
  const generator = new OpenApiGeneratorV3(registry.definitions);
  return generator.generateDocument({
    openapi: "3.0.0",
    info: {title: "Agape Logos API", version: "1.0.0"},
    servers: [{url: "/"}],
  });
}
