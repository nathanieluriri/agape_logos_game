/// Base URL of the deployed backend `api` Cloud Function (2a). Queued mutation
/// endpoints (for example `/levels/{levelId}/result`) are relative and append
/// to this. A single environment for now; `--dart-define` is a later nicety.
const String kApiBaseUrl = 'https://api-jw4yxmunfa-uc.a.run.app';
