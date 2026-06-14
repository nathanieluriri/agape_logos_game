import 'failure.dart';

/// Lightweight Result type. UI layers may convert to Riverpod `AsyncValue`.
sealed class Result<T> {
  const Result();

  R fold<R>(R Function(T value) ok, R Function(Failure failure) err);

  bool get isOk => this is Ok<T>;
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;

  @override
  R fold<R>(R Function(T value) ok, R Function(Failure failure) err) => ok(value);
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;

  @override
  R fold<R>(R Function(T value) ok, R Function(Failure failure) err) =>
      err(failure);
}
