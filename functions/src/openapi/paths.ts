import {z} from "zod";
import {registry} from "./registry";
import {AnswerKeyResponseSchema, CoinsResponseSchema, ProfileResponseSchema, ProfileUpdateSchema} from "../schemas/profile";
import {LevelResultBodySchema} from "../schemas/level_results";
import {DrawBodySchema, PuzzleResultBodySchema} from "../schemas/puzzles";
import {
  InventoryResponseSchema,
  PurchaseBodySchema,
  PurchaseResponseSchema,
  StoreCatalogResponseSchema,
} from "../schemas/store";
import {
  ClaimCoinsResponseSchema,
  ClaimPowerupResponseSchema,
  RewardStatusSchema,
} from "../schemas/rewards";

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
  method: "get",
  path: "/me/coins",
  summary: "Get the current user's coin balance",
  security: bearer,
  responses: {
    200: {
      description: "The user's coin balance",
      content: {"application/json": {schema: CoinsResponseSchema}},
    },
    401: {description: "Missing or invalid token"},
  },
});

registry.registerPath({
  method: "get",
  path: "/me/answer-key",
  summary: "Get the caller's per-user answer-decryption key",
  security: bearer,
  responses: {
    200: {
      description: "The base64 answer key",
      content: {"application/json": {schema: AnswerKeyResponseSchema}},
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
  method: "get",
  path: "/store",
  summary: "List the store catalog (hints + powerups)",
  security: bearer,
  responses: {
    200: {
      description: "The catalog",
      content: {"application/json": {schema: StoreCatalogResponseSchema}},
    },
    401: {description: "Missing or invalid token"},
  },
});

registry.registerPath({
  method: "get",
  path: "/me/inventory",
  summary: "The caller's owned consumables",
  security: bearer,
  responses: {
    200: {
      description: "Owned items",
      content: {"application/json": {schema: InventoryResponseSchema}},
    },
    401: {description: "Missing or invalid token"},
  },
});

registry.registerPath({
  method: "get",
  path: "/rewards",
  summary: "Claim eligibility for the 72h coins and weekly powerup",
  security: bearer,
  responses: {
    200: {
      description: "Reward status",
      content: {"application/json": {schema: RewardStatusSchema}},
    },
    401: {description: "Missing or invalid token"},
  },
});

registry.registerPath({
  method: "post",
  path: "/rewards/claim-coins",
  summary: "Claim the 72h coin reward",
  security: bearer,
  responses: {
    200: {
      description: "Claimed",
      content: {"application/json": {schema: ClaimCoinsResponseSchema}},
    },
    401: {description: "Missing or invalid token"},
    403: {description: "Locked (below the minimum level)"},
    409: {description: "On cooldown"},
  },
});

registry.registerPath({
  method: "post",
  path: "/rewards/claim-powerup",
  summary: "Claim the weekly powerup (shuffle-bag, no repeats until exhausted)",
  security: bearer,
  responses: {
    200: {
      description: "Granted",
      content: {"application/json": {schema: ClaimPowerupResponseSchema}},
    },
    401: {description: "Missing or invalid token"},
    403: {description: "Locked (below the minimum level)"},
    409: {description: "On cooldown"},
  },
});

registry.registerPath({
  method: "post",
  path: "/store/purchase",
  summary: "Spend coins on a store item (idempotent)",
  security: bearer,
  request: {
    headers: z.object({"idempotency-key": z.string()}),
    body: {content: {"application/json": {schema: PurchaseBodySchema}}},
  },
  responses: {
    200: {
      description: "Purchased",
      content: {"application/json": {schema: PurchaseResponseSchema}},
    },
    400: {description: "Unknown item / validation failed"},
    401: {description: "Missing or invalid token"},
    402: {description: "Insufficient coins"},
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

registry.registerPath({
  method: "post",
  path: "/puzzles/draw",
  summary: "Draw a batch of unseen puzzles per requested tier",
  security: bearer,
  request: {
    headers: z.object({"idempotency-key": z.string()}),
    body: {content: {"application/json": {schema: DrawBodySchema}}},
  },
  responses: {
    200: {description: "Assigned puzzles grouped by tier"},
    400: {description: "Validation failed"},
    401: {description: "Missing or invalid token"},
  },
});

registry.registerPath({
  method: "post",
  path: "/puzzles/{puzzleId}/result",
  summary: "Record a solved puzzle and mark the assignment completed",
  security: bearer,
  request: {
    params: z.object({puzzleId: z.string()}),
    headers: z.object({"idempotency-key": z.string()}),
    body: {content: {"application/json": {schema: PuzzleResultBodySchema}}},
  },
  responses: {
    200: {description: "Stored", content: {"application/json": {schema: z.object({ok: z.boolean()})}}},
    400: {description: "Validation failed"},
    401: {description: "Missing or invalid token"},
  },
});

registry.registerPath({
  method: "get",
  path: "/puzzles/assigned",
  summary: "Recover the caller's assigned puzzles by reference",
  security: bearer,
  request: {query: z.object({status: z.enum(["incomplete", "all"]).optional()})},
  responses: {
    200: {description: "Assigned puzzles"},
    400: {description: "Validation failed"},
    401: {description: "Missing or invalid token"},
  },
});
