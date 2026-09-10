import 'package:dio/dio.dart';

import 'package:Note/core/error/exceptions.dart';
import 'package:Note/core/network/api_client.dart';
import 'package:Note/core/network/api_error_parser.dart';
import 'package:Note/core/utils/json_parsers.dart';
import 'package:Note/features/search/domain/entities/search_user.dart';

class UserSearchRemoteDataSource {
  final ApiClient _api;

  const UserSearchRemoteDataSource(this._api);

  Future<List<SearchUser>> search(String keyword) async {
    try {
      final response = await _api.dio.post(
        'https://chat.piisiit.com/api/users/search',
        data: {'keyword': keyword},
        options: Options(headers: {'Accept': '*/*'}),
      );
      return parseUsers(response.data);
    } on DioException catch (error) {
      throw ApiErrorParser.toException(error);
    }
  }

  /// Supports a result list and the app's standard data envelope. Unexpected
  /// bodies are errors, so a server failure cannot look like an empty search.
  static List<SearchUser> parseUsers(Object? body) {
    Object? data = body;
    if (body is Map) {
      final code = body['code'] ?? body['Code'];
      if ((code != null && !{200, 201}.contains(asInt(code))) ||
          body['success'] == false) {
        throw ServerException(
          ApiErrorParser.messageFrom(body),
          statusCode: code == null ? null : asInt(code),
        );
      }
      data = body['data'] ?? body['Data'] ?? body['users'] ?? body['items'];
      if (data is Map) {
        data = data['users'] ?? data['items'] ?? data['results'];
      }
    }
    if (data is! List) {
      throw const ServerException('Unexpected user search response.');
    }
    return data
        .map((item) {
          if (item is! Map) {
            throw const ServerException('Unexpected user search result.');
          }
          final user = SearchUser(
            id: asString(
              item['userId'] ?? item['id'] ?? item['UserId'] ?? item['Id'],
            ),
            account: asString(
              item['account'] ??
                  item['Account'] ??
                  item['username'] ??
                  item['userName'] ??
                  item['email'] ??
                  item['phone'],
            ).trim(),
            fullName: asString(
              item['fullName'] ??
                  item['FullName'] ??
                  item['displayName'] ??
                  item['name'],
            ).trim(),
          );
          if (user.displayName.isEmpty) {
            throw const ServerException(
              'User search returned an unidentified user.',
            );
          }
          return user;
        })
        .toList(growable: false);
  }
}
