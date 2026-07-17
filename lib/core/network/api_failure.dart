enum ApiFailureKind { transport, http, protocol }

/// A failure produced while communicating with or decoding a remote API.
///
/// Only transport failures and explicitly retryable HTTP responses are safe to
/// treat as temporary/offline failures. Client and protocol failures must be
/// surfaced so the app does not report a rejected or malformed operation as a
/// successful local save.
abstract class ApiFailure implements Exception {
  const ApiFailure(
    this.message, {
    required this.kind,
    this.statusCode,
    this.cause,
  });

  final String message;
  final ApiFailureKind kind;
  final int? statusCode;
  final Object? cause;

  bool get isRetryable {
    if (kind == ApiFailureKind.transport) return true;
    if (kind != ApiFailureKind.http) return false;

    final status = statusCode;
    return status == 408 ||
        status == 429 ||
        (status != null && status >= 500 && status <= 599);
  }

  @override
  String toString() => message;
}
