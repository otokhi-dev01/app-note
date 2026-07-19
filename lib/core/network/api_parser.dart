import 'api_exception.dart';

abstract final class ApiParser {
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
}