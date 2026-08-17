/// Low-level errors thrown by the data layer (datasources).
///
/// These never reach controllers: repository implementations catch them and
/// convert them into the [AppFailure] types in `core/error/failures.dart`.
library;

/// The request reached the server but it answered with an error status.
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException(this.message, {this.statusCode});

  @override
  String toString() => 'ServerException($statusCode): $message';
}

/// The request never completed — no connectivity, DNS failure, or timeout.
class NetworkException implements Exception {
  final String message;

  const NetworkException([this.message = 'No internet connection.']);

  @override
  String toString() => 'NetworkException: $message';
}

/// The session is missing or the server rejected the token.
class UnauthorizedException implements Exception {
  final String message;

  const UnauthorizedException([this.message = 'Your session has expired.']);

  @override
  String toString() => 'UnauthorizedException: $message';
}

/// The app asked for something the backend does not implement.
///
/// Carries a user-presentable [message] so controllers can surface the real
/// reason instead of a generic failure. See `ApiCapabilities`.
class UnsupportedFeatureException implements Exception {
  final String message;

  const UnsupportedFeatureException(this.message);

  @override
  String toString() => 'UnsupportedFeatureException: $message';
}
