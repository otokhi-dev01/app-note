import 'package:dio/dio.dart';
import 'package:Note/core/error/exceptions.dart';
import 'package:Note/core/network/api_client.dart';
import 'package:Note/core/network/api_error_parser.dart';
import 'package:Note/core/utils/json_parsers.dart';
import 'package:Note/features/settings/domain/entities/account_device.dart';

class DeviceRemoteDataSource {
  final ApiClient _api;

  const DeviceRemoteDataSource(this._api);

  Future<List<AccountDevice>> getDevices() async {
    try {
      final response = await _api.dio.get(
        'https://chat.piisiit.com/devices',
        options: Options(headers: {'Accept': '*/*'}),
      );
      return parseDevices(response.data);
    } on DioException catch (error) {
      throw ApiErrorParser.toException(error);
    }
  }

  /// Accepts a list or the Chat API's camelCase/PascalCase data envelopes.
  /// Invalid responses remain errors, rather than looking like no devices.
  static List<AccountDevice> parseDevices(Object? body) {
    Object? data = body;
    if (body is Map) {
      final code = body['code'] ?? body['Code'];
      final success = body['success'] ?? body['Success'];
      if ((success != null && !asBool(success)) ||
          (code != null && asInt(code) != 200)) {
        throw ServerException(
          ApiErrorParser.messageFrom(body),
          statusCode: code == null ? null : asInt(code),
        );
      }
      data = body['data'] ?? body['Data'] ?? body['devices'] ?? body['Devices'];
      if (data is Map) {
        data =
            data['devices'] ??
            data['Devices'] ??
            data['items'] ??
            data['Items'];
      }
    }
    if (data is! List) {
      throw const ServerException('Unexpected devices response.');
    }
    return data
        .map((item) {
          if (item is! Map) {
            throw const ServerException('Unexpected device details.');
          }
          String field(String key) => asString(
            item[key] ?? item['${key[0].toUpperCase()}${key.substring(1)}'],
          ).trim();

          final device = AccountDevice(
            id: field('id').isEmpty ? field('deviceId') : field('id'),
            clientDeviceId: field('clientDeviceId'),
            name: field('deviceName'),
            platform: field('platform'),
            model: field('deviceModel'),
            appVersion: field('appVersion'),
            isCurrent: asBool(
              item['isCurrent'] ??
                  item['IsCurrent'] ??
                  item['isCurrentDevice'] ??
                  item['IsCurrentDevice'],
            ),
          );
          if ([
            device.id,
            device.clientDeviceId,
            device.name,
            device.platform,
            device.model,
          ].every((value) => value.isEmpty)) {
            throw const ServerException('Unexpected device details.');
          }
          return device;
        })
        .toList(growable: false);
  }
}
