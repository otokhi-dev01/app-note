import 'dart:convert';

import 'api_exception.dart';

abstract final class ApiParser {
  static void ensureSuccess(
    dynamic response, {
    String fallbackMessage = 'The API request failed.',
  }) {
    final dynamic body = decodeResponse(response);

    if (body is! Map) {
      return;
    }

    final dynamic statusValue = findValue(body, const <String>[
      'status',
    ], recursive: false);
    final int? numericStatus = _toInt(statusValue);
    final bool statusIsHttpCode =
        numericStatus != null && numericStatus >= 100 && numericStatus <= 599;

    final dynamic codeValue = findValue(body, const <String>[
      'code',
      'statusCode',
      'status_code',
    ], recursive: false);
    final int? code =
        _toInt(codeValue) ?? (statusIsHttpCode ? numericStatus : null);

    final bool? explicitSuccess = _toBool(
      findValue(body, const <String>[
        'success',
        'isSuccess',
        'succeeded',
        'ok',
      ], recursive: false),
    );
    final bool? success =
        explicitSuccess ?? (statusIsHttpCode ? null : _toBool(statusValue));

    // Only interpret values in the HTTP error range as failures. Several
    // versions of this API use application codes such as 0 or 1 for a
    // successful request, even though the transport already returned 2xx.
    final bool codeFailed = code != null && (code < 0 || code >= 400);

    final dynamic errorValue = findValue(body, const <String>[
      'error',
      'errors',
      'validationErrors',
      'validation_errors',
    ], recursive: false);
    final bool hasUnqualifiedError =
        success != true && _hasErrorValue(errorValue);

    if (success == true && !codeFailed) {
      return;
    }

    if (success == null && !codeFailed && !hasUnqualifiedError) {
      return;
    }

    throw ApiException(
      message: responseMessage(body, fallback: fallbackMessage),
      statusCode: code,
      responseData: body,
    );
  }

  /// Decodes JSON returned with an incorrect text content type.
  ///
  /// Some deployed API versions return a JSON envelope as a string, or even
  /// as a JSON-encoded string. Decode a few safe layers so every repository
  /// receives the same map/list representation.
  static dynamic decodeResponse(dynamic response) {
    dynamic current = response;

    for (int depth = 0; depth < 3 && current is String; depth++) {
      final String text = current.trim();

      if (text.isEmpty) {
        return current;
      }

      try {
        current = jsonDecode(text);
      } on FormatException {
        return current;
      }
    }

    return current;
  }

  static String responseMessage(
    dynamic response, {
    String fallback = 'The API request failed.',
  }) {
    final dynamic body = decodeResponse(response);

    if (body is String && body.trim().isNotEmpty) {
      return body.trim();
    }

    if (body is! Map) {
      return fallback;
    }

    final dynamic directMessage = findValue(body, const <String>[
      'message',
      'errorMessage',
      'error',
      'detail',
      'title',
    ], recursive: false);
    final String? directText = _messageFromValue(directMessage);

    if (directText != null) {
      return directText;
    }

    final dynamic validationErrors = findValue(body, const <String>[
      'errors',
      'validationErrors',
      'validation_errors',
    ], recursive: true);
    final String? validationText = _messageFromValue(validationErrors);

    if (validationText != null) {
      return validationText;
    }

    final dynamic nestedMessage = findValue(body, const <String>[
      'message',
      'errorMessage',
      'error',
      'detail',
      'title',
    ]);
    final String? nestedText = _messageFromValue(nestedMessage);

    if (nestedText != null) {
      return nestedText;
    }

    // ASP.NET validation APIs sometimes put their field-error map in data.
    final dynamic data = findValue(body, const <String>[
      'data',
    ], recursive: false);
    final String? dataText = _messageFromValue(data);

    return dataText ?? fallback;
  }

  static String? _messageFromValue(dynamic value, {int depth = 0}) {
    if (depth > 8 || value == null) {
      return null;
    }

    final dynamic decoded = decodeResponse(value);

    if (decoded is String) {
      final String text = decoded.trim();
      return text.isEmpty ? null : text;
    }

    if (decoded is List) {
      for (final dynamic item in decoded) {
        final String? message = _messageFromValue(item, depth: depth + 1);

        if (message != null) {
          return message;
        }
      }

      return null;
    }

    if (decoded is Map) {
      for (final dynamic nestedValue in decoded.values) {
        final String? message = _messageFromValue(
          nestedValue,
          depth: depth + 1,
        );

        if (message != null) {
          return message;
        }
      }
    }

    return null;
  }

  static bool _hasErrorValue(dynamic value) {
    final dynamic decoded = decodeResponse(value);

    if (decoded == null || decoded == false) {
      return false;
    }

    if (decoded is String) {
      return decoded.trim().isNotEmpty;
    }

    if (decoded is Iterable) {
      return decoded.isNotEmpty;
    }

    if (decoded is Map) {
      return decoded.isNotEmpty;
    }

    return true;
  }

  static dynamic findValue(
    dynamic value,
    Iterable<String> keys, {
    bool recursive = true,
    int maxDepth = 12,
  }) {
    final Set<String> normalizedKeys = keys.map(_normalizeKey).toSet();

    return _findValue(
      value,
      normalizedKeys,
      recursive: recursive,
      depth: 0,
      maxDepth: maxDepth,
    );
  }

  static dynamic unwrapData(dynamic response) {
    dynamic current = decodeResponse(response);

    while (current is Map) {
      final dynamic data = findValue(current, const <String>[
        'data',
      ], recursive: false);

      if (data != null) {
        current = decodeResponse(data);
        continue;
      }

      final dynamic result = findValue(current, const <String>[
        'result',
      ], recursive: false);

      if (result != null) {
        current = decodeResponse(result);
        continue;
      }

      break;
    }

    return current;
  }

  static List<Map<String, dynamic>> asList(dynamic response) {
    final List<dynamic>? list = _findList(response);

    if (list == null) {
      throw ApiException(
        message: 'The API response does not contain a list.',
        responseData: response,
      );
    }

    return list
        .whereType<Map>()
        .map((Map<dynamic, dynamic> item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Map<String, dynamic> asMap(dynamic response, {bool unwrap = true}) {
    dynamic value = unwrap ? unwrapData(response) : response;

    value = _findObject(value);

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    throw ApiException(
      message: 'The API response does not contain an object.',
      responseData: response,
    );
  }

  static List<dynamic>? _findList(dynamic value) {
    value = decodeResponse(value);

    if (value is List) {
      return value;
    }

    if (value is! Map) {
      return null;
    }

    const List<String> preferredKeys = [
      'data',
      'folder',
      'folders',
      'note',
      'notes',
      'items',
      'records',
      'rows',
      'results',
      'result',
      'list',
      'content',
    ];

    for (final String key in preferredKeys) {
      final dynamic nestedValue = findValue(value, <String>[
        key,
      ], recursive: false);
      final List<dynamic>? result = _findList(nestedValue);

      if (result != null) {
        return result;
      }
    }

    for (final dynamic nestedValue in value.values) {
      final List<dynamic>? result = _findList(nestedValue);

      if (result != null) {
        return result;
      }
    }

    return null;
  }

  static dynamic _findObject(dynamic value) {
    value = decodeResponse(value);

    if (value is! Map) {
      return value;
    }

    const List<String> objectKeys = [
      'note',
      'folder',
      'item',
      'record',
      'result',
    ];

    for (final String key in objectKeys) {
      final dynamic nested = findValue(value, <String>[key], recursive: false);

      if (decodeResponse(nested) is Map) {
        return _findObject(nested);
      }
    }

    return value;
  }

  static int readId(
    dynamic response, {
    List<String> keys = const [
      'Id',
      'id',
      'NoteId',
      'noteId',
      'FolderId',
      'folderId',
      'AttachmentId',
      'attachmentId',
    ],
  }) {
    final int? id = _findId(response, keys: keys);

    if (id == null) {
      throw ApiException(
        message: 'The API response does not contain an ID.',
        responseData: response,
      );
    }

    return id;
  }

  static int? _findId(dynamic value, {required List<String> keys}) {
    value = decodeResponse(value);

    if (value is! Map) {
      return null;
    }

    final Set<String> normalizedKeys = keys.map(_normalizeKey).toSet();

    for (final MapEntry<dynamic, dynamic> entry in value.entries) {
      if (!normalizedKeys.contains(_normalizeKey(entry.key.toString()))) {
        continue;
      }

      final dynamic rawValue = entry.value;

      if (rawValue is int) {
        return rawValue;
      }

      if (rawValue is num) {
        return rawValue.toInt();
      }

      final int? parsed = int.tryParse(rawValue?.toString() ?? '');

      if (parsed != null) {
        return parsed;
      }
    }

    for (final dynamic nestedValue in value.values) {
      final int? result = _findId(nestedValue, keys: keys);

      if (result != null) {
        return result;
      }
    }

    return null;
  }

  static dynamic _findValue(
    dynamic value,
    Set<String> normalizedKeys, {
    required bool recursive,
    required int depth,
    required int maxDepth,
  }) {
    if (depth > maxDepth) {
      return null;
    }

    final dynamic decodedValue = decodeResponse(value);

    if (decodedValue is Map) {
      for (final MapEntry<dynamic, dynamic> entry in decodedValue.entries) {
        if (normalizedKeys.contains(_normalizeKey(entry.key.toString()))) {
          return entry.value;
        }
      }

      if (!recursive) {
        return null;
      }

      for (final dynamic nestedValue in decodedValue.values) {
        final dynamic result = _findValue(
          nestedValue,
          normalizedKeys,
          recursive: true,
          depth: depth + 1,
          maxDepth: maxDepth,
        );

        if (result != null) {
          return result;
        }
      }
    } else if (recursive && decodedValue is List) {
      for (final dynamic nestedValue in decodedValue) {
        final dynamic result = _findValue(
          nestedValue,
          normalizedKeys,
          recursive: true,
          depth: depth + 1,
          maxDepth: maxDepth,
        );

        if (result != null) {
          return result;
        }
      }
    }

    return null;
  }

  static String _normalizeKey(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
  }

  static int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString().trim() ?? '');
  }

  static bool? _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final String text = value?.toString().trim().toLowerCase() ?? '';

    if (text == 'true' ||
        text == '1' ||
        text == 'yes' ||
        text == 'y' ||
        text == 'success' ||
        text == 'succeeded' ||
        text == 'ok') {
      return true;
    }

    if (text == 'false' ||
        text == '0' ||
        text == 'no' ||
        text == 'n' ||
        text == 'failed' ||
        text == 'failure' ||
        text == 'error') {
      return false;
    }

    return null;
  }
}
