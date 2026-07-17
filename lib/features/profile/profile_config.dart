/// The server's default displayName for a freshly provisioned profile (mirrors
/// the backend `DEFAULT_PROFILE.displayName`). When a fetched profile still
/// shows this, the client pushes the Firebase display name up via an optimistic
/// `PUT /me` so the account shows a real name instead of "Player".
const String kDefaultProfileDisplayName = 'Player';

/// Max displayName length the backend `ProfileUpdateSchema` accepts. Names are
/// clamped to this before enqueueing so a long Firebase name never yields a
/// permanent 400.
const int kMaxDisplayNameLength = 30;

/// Mutation kind for the optimistic display-name update; reconcilers key off it.
const String kProfileDisplayNameKind = 'profile_display_name';

/// Handles are unique and case-insensitive. Must match the server's regex exactly
/// (functions/src/services/handle_service.ts), so a handle you can claim is always
/// a handle a friend can search for.
final RegExp kHandlePattern = RegExp(r'^[A-Za-z0-9_]{3,20}$');
const int kMaxHandleLength = 20;
