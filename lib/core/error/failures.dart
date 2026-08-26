sealed class AppFailure {
  final String message;

  const AppFailure(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

final class ServerFailure extends AppFailure {
  final int? statusCode;

  const ServerFailure(super.message, {this.statusCode});
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure([super.message = 'Your session has expired.']);
}

final class UnsupportedFeatureFailure extends AppFailure {
  const UnsupportedFeatureFailure(super.message);
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure([super.message = 'Something went wrong.']);
}
