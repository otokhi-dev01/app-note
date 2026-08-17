/// Domain-level failures.
///
/// Repositories translate the data layer's exceptions into these, so controllers
/// never import Dio or know how the transport failed. Every failure carries a
/// [message] that is safe to show to the user.
sealed class AppFailure {
  final String message;

  const AppFailure(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// The server answered with an error.
final class ServerFailure extends AppFailure {
  final int? statusCode;

  const ServerFailure(super.message, {this.statusCode});
}

/// The device could not reach the server.
final class NetworkFailure extends AppFailure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

/// The session expired or was rejected.
final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure([super.message = 'Your session has expired.']);
}

/// The backend does not implement this action yet.
final class UnsupportedFeatureFailure extends AppFailure {
  const UnsupportedFeatureFailure(super.message);
}

/// The input did not pass a domain rule (empty name, bad phone number, ...).
final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}

/// Anything we could not classify.
final class UnknownFailure extends AppFailure {
  const UnknownFailure([super.message = 'Something went wrong.']);
}
