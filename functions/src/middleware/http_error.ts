// A typed error carrying an HTTP status + optional JSON body. Services throw it
// for expected client errors (402/403/404/409); the error middleware maps it to
// the response. Anything else still becomes a 500.
export class HttpError extends Error {
  constructor(
    public readonly status: number,
    message: string,
    public readonly body?: Record<string, unknown>,
  ) {
    super(message);
    this.name = "HttpError";
  }
}
