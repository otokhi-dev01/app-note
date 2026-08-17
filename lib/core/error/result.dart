import 'package:Note/core/error/failures.dart';

/// The return type of every repository method and use case.
///
/// A sealed class rather than a package like `dartz` — Dart 3 exhaustive
/// switching gives the same safety with no extra dependency:
///
/// ```dart
/// switch (await getFolders()) {
///   case Ok(:final value):    folders.assignAll(value);
///   case Err(:final failure): AppSnackbar.error('Folders', failure.message);
/// }
/// ```
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  /// The value on success, or `null` on failure.
  T? get valueOrNull => switch (this) {
    Ok<T>(:final value) => value,
    Err<T>() => null,
  };

  /// The failure on error, or `null` on success.
  AppFailure? get failureOrNull => switch (this) {
    Ok<T>() => null,
    Err<T>(:final failure) => failure,
  };

  /// The value on success, or [fallback] on failure.
  T orElse(T fallback) => valueOrNull ?? fallback;

  /// Collapse both branches into a single value.
  R fold<R>({
    required R Function(T value) ok,
    required R Function(AppFailure failure) err,
  }) => switch (this) {
    Ok<T>(:final value) => ok(value),
    Err<T>(:final failure) => err(failure),
  };

  /// Transform the success value, leaving a failure untouched.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Ok<T>(:final value) => Ok(transform(value)),
    Err<T>(:final failure) => Err(failure),
  };
}

final class Ok<T> extends Result<T> {
  final T value;

  const Ok(this.value);
}

final class Err<T> extends Result<T> {
  final AppFailure failure;

  const Err(this.failure);
}

/// Shorthand for a call that succeeds with no payload.
const Result<void> okVoid = Ok<void>(null);
