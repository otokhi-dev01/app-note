import 'api_exception.dart';

abstract final class ApiParser {
  static void ensureSuccess(
    dynamic response, {
    String fallbackMessage = 'The API request failed.',
  }) {
    if (response is! Map) {
      return;
    }

    final dynamic codeValue = findValue(
      response,
      const <String>['code', 'statusCode', 'status_code'],
      recursive: false,
    );
    final int? code = _toInt(codeValue);

    final bool? success = _toBool(
      findValue(
        response,
        const <String>['success', 'isSuccess', 'succeeded'],
        recursive: false,
      ),
    );

    final bool codeFailed =
        code != null && code != 0 && (code < 200 || code >= 300);

    if (success != false && !codeFailed) {
      return;
    }

    throw ApiException(
      message: responseMessage(
        response,
        fallback: fallbackMessage,
      ),
      statusCode: code,
      responseData: response,
    );
  }

  static String responseMessage(
    dynamic response, {
    String fallback = 'The API request failed.',
  }) {
    if (response is String && response.trim().isNotEmpty) {
      return response.trim();
    }

    if (response is! Map) {
      return fallback;
    }

    final dynamic message = findValue(
      response,
      const <String>[
        'message',
        'errorMessage',
        'error',
        'detail',
        'title',
      ],
      recursive: false,
    );

    final String text = message?.toString().trim() ?? '';

    return text.isEmpty ? fallback : text;
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
    dynamic current = response;

    while (current is Map) {
      if (current.containsKey('data')) {
        current = current['data'];
        continue;
      }

      if (current.containsKey('result')) {
        current = current['result'];
        continue;
      }

      break;
    }

    return current;
  }

  static List<Map<String, dynamic>> asList(
      dynamic response,
      ) {
    final List<dynamic>? list = _findList(response);

    if (list == null) {
      throw ApiException(
        message:
        'The API response does not contain a list.',
        responseData: response,
      );
    }

    return list
        .whereType<Map>()
        .map(
          (Map<dynamic, dynamic> item) =>
      Map<String, dynamic>.from(item),
    )
        .toList();
  }

  static Map<String, dynamic> asMap(
      dynamic response, {
        bool unwrap = true,
      }) {
    dynamic value =
    unwrap ? unwrapData(response) : response;

    value = _findObject(value);

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    throw ApiException(
      message:
      'The API response does not contain an object.',
      responseData: response,
    );
  }

  static List<dynamic>? _findList(dynamic value) {
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
      if (!value.containsKey(key)) {
        continue;
      }

      final List<dynamic>? result =
      _findList(value[key]);

      if (result != null) {
        return result;
      }
    }

    for (final dynamic nestedValue in value.values) {
      final List<dynamic>? result =
      _findList(nestedValue);

      if (result != null) {
        return result;
      }
    }

    return null;
  }

  static dynamic _findObject(dynamic value) {
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
      final dynamic nested = value[key];

      if (nested is Map) {
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
    final int? id = _findId(
      response,
      keys: keys,
    );

    if (id == null) {
      throw ApiException(
        message:
        'The API response does not contain an ID.',
        responseData: response,
      );
    }

    return id;
  }

  static int? _findId(
      dynamic value, {
        required List<String> keys,
      }) {
    if (value is! Map) {
      return null;
    }

    for (final String key in keys) {
      final dynamic rawValue = value[key];

      if (rawValue is int) {
        return rawValue;
      }

      if (rawValue is num) {
        return rawValue.toInt();
      }

      final int? parsed = int.tryParse(
        rawValue?.toString() ?? '',
      );

      if (parsed != null) {
        return parsed;
      }
    }

    for (final dynamic nestedValue in value.values) {
      final int? result = _findId(
        nestedValue,
        keys: keys,
      );

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

    if (value is Map) {
      for (final MapEntry<dynamic, dynamic> entry in value.entries) {
        if (normalizedKeys.contains(_normalizeKey(entry.key.toString()))) {
          return entry.value;
        }
      }

      if (!recursive) {
        return null;
      }

      for (final dynamic nestedValue in value.values) {
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
    } else if (recursive && value is List) {
      for (final dynamic nestedValue in value) {
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

    if (text == 'true' || text == '1' || text == 'success') {
      return true;
    }

    if (text == 'false' || text == '0' || text == 'failed') {
      return false;
    }

    return null;
  }
}
