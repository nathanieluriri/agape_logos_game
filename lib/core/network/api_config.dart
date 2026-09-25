/// Base URL of the deployed backend `api` Cloud Function (2a). Queued mutation
/// endpoints (for example `/levels/{levelId}/result`) are relative and append
/// to this. `--dart-define=API_BASE_URL=...` points it at a local server.
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api-jw4yxmunfa-uc.a.run.app',
);
