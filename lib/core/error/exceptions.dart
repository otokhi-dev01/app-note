library;

class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException(this.message, {this.statusCode});

  @override
  String toString() => 'ServerException($statusCode): $message';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException([this.message = 'No internet connection.']);

  @override
  String toString() => 'NetworkException: $message';
}

class UnauthorizedException implements Exception {
  final String message;

  const UnauthorizedException([this.message = 'Your session has expired.']);

  @override
  String toString() => 'UnauthorizedException: $message';
}

class UnsupportedFeatureException implements Exception {
  final String message;

  const UnsupportedFeatureException(this.message);

  @override
  String toString() => 'UnsupportedFeatureException: $message';
}
