import 'package:dio/dio.dart';

import 'package:Note/core/error/exceptions.dart';

/// Turns a raw API payload or a [DioException] into a user-presentable message.
///
/// Was `FolderService.getApiErrorMessage`; lifted here because every feature
/// needs the same treatment of the backend's `{ message, data: { field: [..] } }`
/// error envelope.
class ApiErrorParser {
  ApiErrorParser._();

  /// Pulls the most specific message out of an API response body.
  ///
  /// Prefers the first field-level validation message, then the top-level
  /// `message`, then a generic fallback.
  static String messageFrom(dynamic responseData) {
    if (responseData is! Map) return 'An unexpected error occurred.';

    final data = responseData['data'];
    if (data is Map) {
      for (final value in data.values) {
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }
      }
    }

    return responseData['message']?.toString() ?? 'Something went wrong.';
  }

  /// Maps a Dio error onto the exception the repository layer expects.
  static Exception toException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException('The server took too long to respond.');
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.cancel:
        return const NetworkException('The request was cancelled.');
      default:
        final status = error.response?.statusCode;
        if (status == 401 || status == 403) {
          return UnauthorizedException(messageFrom(error.response?.data));
        }
        return ServerException(
          messageFrom(error.response?.data),
          statusCode: status,
        );
    }
  }
}
