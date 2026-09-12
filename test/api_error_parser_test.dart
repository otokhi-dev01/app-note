import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Note/core/error/exceptions.dart';
import 'package:Note/core/network/api_error_parser.dart';

void main() {
  Exception parse(int status, Object? body, {String path = '/api/folder'}) {
    final request = RequestOptions(
      baseUrl: 'https://note.piisiit.com',
      path: path,
    );
    return ApiErrorParser.toException(
      DioException(
        requestOptions: request,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: request,
          statusCode: status,
          data: body,
        ),
      ),
    );
  }

  test(
    'empty Note authorization responses explain the error without a false logout message',
    () {
      for (final body in [
        null,
        '',
        <String, dynamic>{},
        {'message': ''},
      ]) {
        for (final path in [
          '/api/folder',
          '/api/folder/save',
          '/api/note/save',
        ]) {
          final error = parse(401, body, path: path) as UnauthorizedException;
          expect(error.message, contains('notes server'));
          expect(error.message, contains('(401)'));
        }
      }
    },
  );

  test(
    'empty and HTML responses retain the HTTP status in readable errors',
    () {
      for (final status in [403, 404, 500, 502]) {
        final error = parse(status, '<html>Server error</html>');
        final message = switch (error) {
          UnauthorizedException(:final message) => message,
          ServerException(:final message) => message,
          _ => throw StateError('Unexpected error type'),
        };
        expect(message, contains('($status)'));
        expect(message, isNot(contains('<html>')));
      }
    },
  );

  test('server validation messages take precedence over fallback text', () {
    final error =
        parse(400, {
              'message': 'Validation failed',
              'errors': {
                'Name': ['Name is required'],
              },
            })
            as ServerException;
    expect(error.message, 'Name is required');
    final unauthorized =
        parse(401, {'Message': 'Invalid credential!'}) as UnauthorizedException;
    expect(unauthorized.message, 'Invalid credential!');
  });
}
