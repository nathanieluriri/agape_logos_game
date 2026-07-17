import {Response, Router} from "express";
import {AuthedRequest, requireAuth} from "../middleware/auth";
import {asyncHandler} from "../middleware/error";
import {validate, ValidatedRequest} from "../middleware/validate";
import {
  RegisterDeviceBody,
  RegisterDeviceBodySchema,
  UnregisterDeviceParams,
  UnregisterDeviceParamsSchema,
} from "../schemas/devices";
import {registerDevice, unregisterDevice} from "../services/messaging_service";

export const devicesRouter = Router();

// POST /me/devices - register (or refresh) an FCM device token for push.
devicesRouter.post(
  "/me/devices",
  requireAuth,
  validate({body: RegisterDeviceBodySchema}),
  asyncHandler<AuthedRequest & ValidatedRequest>(async (req, res: Response) => {
    const body = req.valid?.body as RegisterDeviceBody;
    await registerDevice(req.uid as string, body.token, body.platform);
    res.status(200).json({ok: true});
  }),
);

// DELETE /me/devices/:token - drop a device token (sign-out, uninstall).
devicesRouter.delete(
  "/me/devices/:token",
  requireAuth,
  validate({params: UnregisterDeviceParamsSchema}),
  asyncHandler<AuthedRequest & ValidatedRequest>(async (req, res: Response) => {
    const params = req.valid?.params as UnregisterDeviceParams;
    await unregisterDevice(req.uid as string, params.token);
    res.status(200).json({ok: true});
  }),
);
