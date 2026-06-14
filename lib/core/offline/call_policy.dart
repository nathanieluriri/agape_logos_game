/// Documents how a repository call interacts with the network and local cache.
/// Repositories pick exactly one policy per call so the behaviour is explicit.
sealed class CallPolicy {
  const CallPolicy();
}

/// Pure read; fails with `OfflineFailure` when unreachable; never cached.
class OnlineOnly extends CallPolicy {
  const OnlineOnly();
}

/// Fetch when online (write-through to cache); serve cache when offline.
class CachedRead extends CallPolicy {
  const CachedRead({this.networkFirst = true});

  /// When online: prefer the network and fall back to cache on failure.
  /// When false: serve cache first and refresh in the background.
  final bool networkFirst;
}

/// Apply locally immediately; enqueue the mutation; sync later.
class OptimisticWrite extends CallPolicy {
  const OptimisticWrite();
}
