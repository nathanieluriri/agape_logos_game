import {z} from "zod";
import {registry} from "./registry";
import {
  FriendRequestBodySchema,
  FriendRespondBodySchema,
  FriendsResponseSchema,
  MatchHistoryResponseSchema,
  OkResponseSchema,
  PrivacyBodySchema,
  PublicProfileDetailResponseSchema,
  UserSearchResponseSchema,
} from "../schemas/social";

const bearer = [{bearerAuth: [] as string[]}];
const idem = z.object({"idempotency-key": z.string()});

registry.registerPath({
  method: "put",
  path: "/me/privacy",
  summary: "Set the caller's profile public or private (default private)",
  security: bearer,
  request: {
    headers: idem,
    body: {content: {"application/json": {schema: PrivacyBodySchema}}},
  },
  responses: {
    200: {description: "Updated", content: {"application/json": {schema: OkResponseSchema}}},
    400: {description: "Validation failed"},
    401: {description: "Missing or invalid token"},
  },
});

registry.registerPath({
  method: "get",
  path: "/users/search",
  summary: "Prefix-search public profiles by handle or display name",
  security: bearer,
  request: {query: z.object({q: z.string(), limit: z.number().int().optional()})},
  responses: {
    200: {description: "Matching public profiles", content: {"application/json": {schema: UserSearchResponseSchema}}},
    400: {description: "Validation failed"},
    401: {description: "Missing or invalid token"},
  },
});

registry.registerPath({
  method: "get",
  path: "/users/{uid}/public",
  summary: "A user's public profile projection with recent match history",
  security: bearer,
  request: {params: z.object({uid: z.string()})},
  responses: {
    200: {description: "Public profile", content: {"application/json": {schema: PublicProfileDetailResponseSchema}}},
    401: {description: "Missing or invalid token"},
    403: {description: "Private (or non-existent) profile"},
  },
});

registry.registerPath({
  method: "post",
  path: "/friends/request",
  summary: "Send a friend request by uid or @handle (idempotent)",
  security: bearer,
  request: {
    headers: idem,
    body: {content: {"application/json": {schema: FriendRequestBodySchema}}},
  },
  responses: {
    200: {description: "Sent", content: {"application/json": {schema: OkResponseSchema}}},
    400: {description: "Self-target / validation failed"},
    401: {description: "Missing or invalid token"},
    404: {description: "Target not found"},
  },
});

registry.registerPath({
  method: "post",
  path: "/friends/respond",
  summary: "Accept or decline an incoming friend request",
  security: bearer,
  request: {
    headers: idem,
    body: {content: {"application/json": {schema: FriendRespondBodySchema}}},
  },
  responses: {
    200: {description: "Handled", content: {"application/json": {schema: OkResponseSchema}}},
    401: {description: "Missing or invalid token"},
    404: {description: "No such request"},
  },
});

registry.registerPath({
  method: "get",
  path: "/friends",
  summary: "The caller's friends and incoming requests",
  security: bearer,
  responses: {
    200: {description: "Friends + requests", content: {"application/json": {schema: FriendsResponseSchema}}},
    401: {description: "Missing or invalid token"},
  },
});

registry.registerPath({
  method: "get",
  path: "/me/matches",
  summary: "The caller's match history (newest first, capped)",
  security: bearer,
  request: {query: z.object({limit: z.number().int().optional()})},
  responses: {
    200: {description: "Match history", content: {"application/json": {schema: MatchHistoryResponseSchema}}},
    400: {description: "Validation failed"},
    401: {description: "Missing or invalid token"},
  },
});
