import {z} from "zod";

// POST /me/devices body: register (or refresh) an FCM device token.
export const RegisterDeviceBodySchema = z
  .object({
    token: z.string().min(10),
    platform: z.enum(["android", "web"]),
  })
  .strict();
export type RegisterDeviceBody = z.infer<typeof RegisterDeviceBodySchema>;

// DELETE /me/devices/:token params.
export const UnregisterDeviceParamsSchema = z.object({
  token: z.string().min(10),
});
export type UnregisterDeviceParams = z.infer<typeof UnregisterDeviceParamsSchema>;
