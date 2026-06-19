import {z} from "zod";
import {registry} from "./registry";
import {ProfileResponseSchema, ProfileUpdateSchema} from "../schemas/profile";
import {LevelResultBodySchema} from "../schemas/level_results";

const bearer = [{bearerAuth: [] as string[]}];

registry.registerPath({
  method: "get",
  path: "/me",
  summary: "Get or auto-create the current user's profile",
  security: bearer,
  responses: {
    200: {
      description: "The user's profile",
      content: {"application/json": {schema: ProfileResponseSchema}},
    },
    401: {description: "Missing or invalid token"},
  },
});

registry.registerPath({
  method: "put",
  path: "/me",
  summary: "Update editable profile fields",
  security: bearer,
  request: {
    body: {content: {"application/json": {schema: ProfileUpdateSchema}}},
  },
  responses: {
    200: {
      description: "The updated profile",
      content: {"application/json": {schema: ProfileResponseSchema}},
    },
    400: {description: "Validation failed"},
    401: {description: "Missing or invalid token"},
  },
});

registry.registerPath({
  method: "post",
  path: "/levels/{levelId}/result",
  summary: "Submit an idempotent level result",
  security: bearer,
  request: {
    params: z.object({levelId: z.number().int()}),
    headers: z.object({"idempotency-key": z.string()}),
    body: {content: {"application/json": {schema: LevelResultBodySchema}}},
  },
  responses: {
    200: {
      description: "Stored",
      content: {"application/json": {schema: z.object({ok: z.boolean()})}},
    },
    400: {description: "Validation failed"},
    401: {description: "Missing or invalid token"},
  },
});
