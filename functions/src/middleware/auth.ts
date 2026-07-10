import {NextFunction, Request, Response} from "express";
import {auth} from "../firebase";

export interface AuthedRequest extends Request {
  uid?: string;
  isGuest?: boolean;
}

// Verifies "Authorization: Bearer <Firebase ID token>" and attaches req.uid.
// Sub-phase 2d will add Firebase App Check verification here.
export async function requireAuth(
  req: AuthedRequest,
  res: Response,
  next: NextFunction,
): Promise<void> {
  const header = req.header("authorization") ?? "";
  const match = header.match(/^Bearer (.+)$/);
  if (!match) {
    res.status(401).json({error: "missing or malformed Authorization header"});
    return;
  }
  try {
    const decoded = await auth.verifyIdToken(match[1]);
    req.uid = decoded.uid;
    // PLAN: decoded.firebase.sign_in_provider is on DecodedIdToken; anonymous
    // Firebase users report "anonymous". Additive; no existing route changes.
    req.isGuest = decoded.firebase?.sign_in_provider === "anonymous";
    next();
  } catch {
    res.status(401).json({error: "invalid token"});
  }
}
