/// A typed, human-readable failure returned by the data layer instead of a raw
/// exception. Add subclasses as each repository is migrated.
sealed class AppFailure {
  const AppFailure(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

/// A failure that occurred while reading from or writing to the local database.
final class DatabaseFailure extends AppFailure {
  const DatabaseFailure(super.message, [super.cause]);
}

/// A lightweight tagged-union result for operations that can fail.
///
/// Data-layer methods should return [Result] instead of throwing so callers
/// handle failures explicitly (no hidden control flow).
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;

  bool get isFailure => this is Failure<T>;

  T? get valueOrNull => switch (this) {
        Success<T>(:final value) => value,
        Failure<T>() => null,
      };

  AppFailure? get failureOrNull => switch (this) {
        Failure<T>(:final failure) => failure,
        Success<T>() => null,
      };

  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        Success<T>(:final value) => Success<R>(transform(value)),
        Failure<T>(:final failure) => Failure<R>(failure),
      };

  T getOrElse(T Function(AppFailure failure) orElse) => switch (this) {
        Success<T>(:final value) => value,
        Failure<T>(:final failure) => orElse(failure),
      };

  R when<R>({
    required R Function(T value) success,
    required R Function(AppFailure failure) onFailure,
  }) =>
      switch (this) {
        Success<T>(:final value) => success(value),
        Failure<T>(:final failure) => onFailure(failure),
      };
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class Failure<T> extends Result<T> {
  const Failure(this.failure);
  final AppFailure failure;
}
