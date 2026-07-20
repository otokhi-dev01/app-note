import 'package:note_app/core/network/api_client.dart';
import 'package:note_app/core/network/api_endpoints.dart';
import 'package:note_app/core/network/api_exception.dart';
import 'package:note_app/feature/folders/domain/entities/folder_entity.dart';
import 'package:note_app/feature/folders/domain/repositories/folder_repository.dart';

class FolderRepositoryImpl implements FolderRepository {
  final ApiClient apiClient;

  const FolderRepositoryImpl({
    required this.apiClient,
  });

  @override
  Future<List<FolderEntity>> getFolders() async {
    final dynamic response = await apiClient.get(
      ApiEndpoints.folders,
      requiresAuth: true,
      useAuthBaseUrl: false,
    );

    _validateResponse(response);

    final List<dynamic> items = _extractFolders(
      response,
    );

    return items
        .whereType<Map>()
        .map(
          (Map<dynamic, dynamic> item) {
        return FolderEntity.fromJson(
          item.map(
                (
                dynamic key,
                dynamic value,
                ) {
              return MapEntry<String, dynamic>(
                key.toString(),
                value,
              );
            },
          ),
        );
      },
    )
        .where(
          (FolderEntity folder) {
        return folder.id > 0;
      },
    )
        .toList(
      growable: false,
    );
  }

  @override
  Future<void> saveFolder({
    required int id,
    required String name,
    required String iconName,
    required String colorValue,
    required int sortOrder,
  }) async {
    final String cleanName = name.trim();

    if (cleanName.isEmpty) {
      throw const ApiException(
        message: 'Folder name is required.',
      );
    }

    final dynamic response = await apiClient.post(
      ApiEndpoints.saveFolder,
      requiresAuth: true,
      useAuthBaseUrl: false,
      body: <String, dynamic>{
        'id': id,
        'name': cleanName,
        'iconName': iconName.trim().isEmpty
            ? 'folder'
            : iconName.trim(),
        'colorValue': colorValue.trim().isEmpty
            ? '#2196F3'
            : colorValue.trim(),
        'sortOrder': sortOrder,
      },
    );

    _validateResponse(response);
  }

  @override
  Future<void> deleteOrRestoreFolder({
    required int id,
    required bool isDelete,
  }) async {
    if (id <= 0) {
      throw const ApiException(
        message: 'Invalid folder ID.',
      );
    }

    final dynamic response = await apiClient.post(
      ApiEndpoints.deleteRestoreFolder,
      requiresAuth: true,
      useAuthBaseUrl: false,
      body: <String, dynamic>{
        'id': id,
        'isDelete': isDelete,
      },
    );

    _validateResponse(response);
  }

  List<dynamic> _extractFolders(
      dynamic response,
      ) {
    final dynamic body = _unwrapResponse(
      response,
    );

    if (body is List) {
      return body;
    }

    if (body is! Map) {
      return <dynamic>[];
    }

    final Map<String, dynamic> root = body.map(
          (
          dynamic key,
          dynamic value,
          ) {
        return MapEntry<String, dynamic>(
          key.toString(),
          value,
        );
      },
    );

    final dynamic data = _readValue(
      root,
      const <String>['data'],
    );

    if (data is List) {
      return data;
    }

    if (data is Map) {
      final Map<String, dynamic> dataMap = data.map(
            (
            dynamic key,
            dynamic value,
            ) {
          return MapEntry<String, dynamic>(
            key.toString(),
            value,
          );
        },
      );

      final dynamic folders = _readValue(
        dataMap,
        const <String>[
          'folder',
          'folders',
          'items',
          'rows',
          'records',
        ],
      );

      if (folders is List) {
        return folders;
      }
    }

    final dynamic folders = _readValue(
      root,
      const <String>[
        'folder',
        'folders',
        'items',
        'rows',
        'records',
      ],
    );

    return folders is List
        ? folders
        : <dynamic>[];
  }

  void _validateResponse(
      dynamic response,
      ) {
    final dynamic body = _unwrapResponse(
      response,
    );

    if (body == null) {
      throw const ApiException(
        message: 'The server returned an empty response.',
      );
    }

    if (body is! Map) {
      return;
    }

    final Map<String, dynamic> map = body.map(
          (
          dynamic key,
          dynamic value,
          ) {
        return MapEntry<String, dynamic>(
          key.toString(),
          value,
        );
      },
    );

    final int? code = _toInt(
      _readValue(
        map,
        const <String>[
          'code',
          'statusCode',
          'status_code',
        ],
      ),
    );

    final bool? success = _toBool(
      _readValue(
        map,
        const <String>[
          'success',
          'isSuccess',
          'succeeded',
        ],
      ),
    );

    if (success == false) {
      throw ApiException(
        message: _messageFromMap(map),
        statusCode: code,
        responseData: body,
      );
    }

    if (code != null &&
        code != 0 &&
        (code < 200 || code >= 300)) {
      throw ApiException(
        message: _messageFromMap(map),
        statusCode: code,
        responseData: body,
      );
    }
  }

  dynamic _unwrapResponse(
      dynamic response,
      ) {
    if (response == null ||
        response is Map ||
        response is List ||
        response is String ||
        response is num ||
        response is bool) {
      return response;
    }

    try {
      return (response as dynamic).data;
    } catch (_) {
      return response;
    }
  }

  dynamic _readValue(
      Map<String, dynamic> map,
      List<String> keys,
      ) {
    for (final String key in keys) {
      for (final MapEntry<String, dynamic> entry
      in map.entries) {
        if (entry.key.toLowerCase() ==
            key.toLowerCase()) {
          return entry.value;
        }
      }
    }

    return null;
  }

  String _messageFromMap(
      Map<String, dynamic> map,
      ) {
    final dynamic message = _readValue(
      map,
      const <String>[
        'message',
        'error',
        'errorMessage',
        'detail',
      ],
    );

    final String text =
        message?.toString().trim() ?? '';

    return text.isEmpty
        ? 'The folder request failed.'
        : text;
  }

  int? _toInt(
      dynamic value,
      ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ?? '',
    );
  }

  bool? _toBool(
      dynamic value,
      ) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final String text =
        value?.toString().trim().toLowerCase() ??
            '';

    if (text == 'true' ||
        text == '1' ||
        text == 'success') {
      return true;
    }

    if (text == 'false' ||
        text == '0' ||
        text == 'failed') {
      return false;
    }

    return null;
  }
}