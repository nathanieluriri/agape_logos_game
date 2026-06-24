import {NextFunction, Request, Response} from "express";
import {ZodTypeAny} from "zod";

export interface ValidationSchemas {
  params?: ZodTypeAny;
  body?: ZodTypeAny;
  headers?: ZodTypeAny;
}

export interface ValidatedRequest extends Request {
  valid?: {params?: unknown; body?: unknown; headers?: unknown};
}

// Validates the requested parts with zod. On the first failure it responds 400
// and stops; on success it attaches parsed values to req.valid and continues.
export function validate(schemas: ValidationSchemas) {
  return (req: ValidatedRequest, res: Response, next: NextFunction): void => {
    const valid: {params?: unknown; body?: unknown; headers?: unknown} = {};
    const parts = ["params", "body", "headers"] as const;
    for (const part of parts) {
      const schema = schemas[part];
      if (!schema) continue;
      const result = schema.safeParse(req[part]);
      if (!result.success) {
        res.status(400).json({error: "validation failed", issues: result.error.issues});
        return;
      }
      valid[part] = result.data;
    }
    req.valid = valid;
    next();
  };
}
