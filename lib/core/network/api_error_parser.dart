import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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
            final candidate = value.first.toString();
            if (!_looksLikeInternalError(candidate)) return candidate;
          }
        }
      }
    }

    final message =
        (responseData['message'] ??
                responseData['Message'] ??
                responseData['error'] ??
                responseData['Error'] ??
                responseData['detail'] ??
                responseData['title'])
            ?.toString()
            .trim();
    if (message != null && message.isNotEmpty) {
      if (!_looksLikeInternalError(message)) return message;
      // The backend leaked a raw server-side exception (a stack trace, a
      // database/ORM error, ...) instead of a message meant for an end user.
      // Never show or log that verbatim: the server could echo credentials.
      // Record only that details were suppressed and use a generic message.
      if (kDebugMode) {
        debugPrint('[API] Suppressed internal server error details.');
      }
    }
    return fallback ?? 'Something went wrong.';
  }

  /// Heuristic for "this reads like a raw exception/stack trace, not
  /// something a backend meant to show an end user" — e.g. an ASP.NET/EF
  /// Core error such as "The relationship from 'UserSession' to
  /// 'UserDevice' ... cannot target the primary key ... because it is not
  /// compatible." Real validation messages are short, plain sentences;
  /// framework/database exceptions are long, technical, and named-entity-heavy.
  static bool _looksLikeInternalError(String message) {
    final lower = message.toLowerCase();
    const markers = [
      'exception',
      'stack trace',
      'stacktrace',
      'at system.',
      'entityframework',
      'sqlexception',
      'nullreferenceexception',
      'foreign key',
      'primary key',
      'cannot target',
      'microsoft.',
      'system.data.',
      'inner exception',
    ];
    if (markers.any(lower.contains)) return true;
    // Long messages naming several quoted identifiers read like an internal
    // diagnostic dump rather than user-facing copy.
    if (message.length > 220 && "'".allMatches(message).length >= 4) {
      return true;
    }
    return false;
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
        final requiresAuth =
            error.requestOptions.extra['requiresAuth'] != false;
        final fallback = switch (status) {
          400 =>
            'The server rejected the request (400). Please check your input or contact support.',
          401 when !requiresAuth => 'Invalid account or password.',
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
