/// Sealed failure hierarchy returned by repositories and the offline engine.
sealed class Failure {
  const Failure(this.message);
  final String message;
}

/// Device is offline / endpoint unreachable.
class OfflineFailure extends Failure {
  const OfflineFailure([super.message = 'No network connection']);
}

/// Transient network error (timeout, 5xx) — safe to retry.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error']);
}

/// Server returned an error response.
class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.statusCode});
  final int? statusCode;
}

/// Local cache/storage error.
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Unknown error']);
}
