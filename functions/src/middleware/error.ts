import {NextFunction, Request, Response} from "express";

// Wraps an async route so rejected promises reach the error middleware
// (Express 4 does not catch async throws on its own).
export function asyncHandler<Req extends Request = Request>(
  fn: (req: Req, res: Response, next: NextFunction) => Promise<unknown>,
) {
  return (req: Request, res: Response, next: NextFunction): void => {
    fn(req as Req, res, next).catch(next);
  };
}

export function notFound(_req: Request, res: Response): void {
  res.status(404).json({error: "not found"});
}

// Express recognizes error middleware by its four parameters; next is required
// in the signature even though it is unused here.
// eslint-disable-next-line @typescript-eslint/no-unused-vars
export function errorHandler(_err: unknown, _req: Request, res: Response, _next: NextFunction): void {
  res.status(500).json({error: "internal error"});
}
