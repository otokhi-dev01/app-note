class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic responseData;

  const ApiException({
    required this.message,
    this.statusCode,
    this.responseData,
  });

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() {
    if (statusCode == null) {
      return message;
    }

    return '$message (HTTP $statusCode)';
  }
}