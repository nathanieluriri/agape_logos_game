/// Route paths for the social feature (used by the router + navigation calls),
/// kept in one place so the pages and the wiring cannot drift apart.
const String kFriendsRoute = '/friends';
const String kFriendsSearchRoute = '/friends/search';
const String kHistoryRoute = '/history';

/// Builds the public-profile route for [uid] (route pattern `/profile/:uid`).
String publicProfileRoute(String uid) => '/profile/$uid';

/// The endpoint paths (single source of truth for the remote).
const String kPrivacyEndpoint = '/me/privacy';
const String kUserSearchEndpoint = '/users/search';
const String kFriendsEndpoint = '/friends';
const String kFriendRequestEndpoint = '/friends/request';
const String kFriendRespondEndpoint = '/friends/respond';
const String kMatchesEndpoint = '/me/matches';
String publicProfileEndpoint(String uid) => '/users/$uid/public';
