import 'package:note_app/core/network/api_exception.dart';
import 'package:note_app/core/network/api_parser.dart';

class FolderApiResponseValidator {
  const FolderApiResponseValidator();

  void ensureCommandSucceeded(dynamic response) {
    if (response == null) {
      // ApiClient only returns null after a successful no-content response.
      return;
    }

    ensureSuccessfulEnvelope(response);

    if (response is bool) {
      if (!response) {
        throw const ApiException(message: 'The folder request failed.');
      }

      return;
    }

    if (response is Map) {
      final Map<String, dynamic> map = _convertMap(response);
      final dynamic data = _readValue(map, const <String>['data', 'result']);

      if (data is bool && !data) {
        throw ApiException(
          message: _messageFromMap(map),
          responseData: response,
        );
      }

      if (data is Map) {
        ensureSuccessfulEnvelope(data);
      }

      return;
    }

    if (response is String) {
      final String message = response.trim();

      if (message.isNotEmpty && !_looksLikeFailure(message)) {
        return;
      }
    }

    if (response is num) {
      return;
    }

    throw ApiException(
      message: 'The server returned an invalid folder response.',
      responseData: response,
    );
  }

  void ensureSuccessfulEnvelope(dynamic response) {
    ApiParser.ensureSuccess(
      response,
      fallbackMessage: 'The folder request failed.',
    );
  }

  String responseMessage(dynamic response) {
    final dynamic message = ApiParser.findValue(
      ApiParser.decodeResponse(response),
      const <String>['message', 'detail'],
    );

    return message is String ? message.trim() : '';
  }

  Map<String, dynamic> _convertMap(Map<dynamic, dynamic> map) {
    return map.map(
      (dynamic key, dynamic value) =>
          MapEntry<String, dynamic>(key.toString(), value),
    );
  }

  dynamic _readValue(Map<String, dynamic> map, Iterable<String> keys) {
    final Map<String, dynamic> normalizedMap = <String, dynamic>{
      for (final MapEntry<String, dynamic> entry in map.entries)
        entry.key.toLowerCase(): entry.value,
    };

    for (final String key in keys) {
      final String normalizedKey = key.toLowerCase();

      if (normalizedMap.containsKey(normalizedKey)) {
        return normalizedMap[normalizedKey];
      }
    }

    return null;
  }

  String _messageFromMap(Map<String, dynamic> map) {
    return ApiParser.responseMessage(
      map,
      fallback: 'The folder request failed.',
    );
  }

  bool _looksLikeFailure(String value) {
    final String text = value.toLowerCase();

    return text.contains('fail') ||
        text.contains('error') ||
        text.contains('invalid') ||
        text.contains('denied');
  }
}
