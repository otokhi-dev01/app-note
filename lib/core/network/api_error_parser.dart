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
  static String messageFrom(dynamic responseData, {String? fallback}) {
    if (responseData is! Map) {
      return fallback ?? 'An unexpected error occurred.';
    }

    for (final details in [
      responseData['errors'] ?? responseData['Errors'],
      responseData['data'] ?? responseData['Data'],
    ]) {
      if (details is Map) {
        for (final entry in details.entries) {
          // JSON deserialization diagnostics expose server implementation
          // details; the top-level validation message is clearer in that case.
          if (entry.key.toString().startsWith(r'$')) continue;
          final value = entry.value;
          if (value is List && value.isNotEmpty) {
            return value.first.toString();
          }
        }
      }
    }

    final message =
        (responseData['message'] ??
                responseData['Message'] ??
                responseData['detail'] ??
                responseData['title'])
            ?.toString()
            .trim();
    return message != null && message.isNotEmpty
        ? message
        : fallback ?? 'Something went wrong.';
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
        final path = error.requestOptions.uri.path;
        final isNoteRequest =
            path == '/api/folder' ||
            path.startsWith('/api/folder/') ||
            path == '/api/note' ||
            path.startsWith('/api/note/');
        final fallback = switch (status) {
          401 when isNoteRequest =>
            'The notes server could not authorize this request (401).',
          401 => 'Your session has expired. Please sign in again.',
          403 => 'You do not have permission to access this item (403).',
          404 => 'The requested service could not be found (404).',
          429 => 'Too many requests. Please wait and try again.',
          final int code when code >= 500 =>
            'The server could not complete the request ($code). Please try again.',
          final int code => 'The request failed ($code). Please try again.',
          _ => 'Could not reach the server. Please try again.',
        };
        final message = messageFrom(error.response?.data, fallback: fallback);
        if (status == 401 || status == 403) {
          return UnauthorizedException(message);
        }
        return ServerException(message, statusCode: status);
    }
  }
}
