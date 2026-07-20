import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../entities/folder_entity.dart';

abstract class FolderRepository {
  Future<List<FolderEntity>> getFolders();

  Future<void> saveFolder({
    required int id,
    required String name,
    required String iconName,
    required String colorValue,
    required int sortOrder,
  });

  Future<void> deleteOrRestoreFolder({required int id, required bool isDelete});
}

class FolderRepositoryImpl implements FolderRepository {
  final ApiClient apiClient;

  const FolderRepositoryImpl({required this.apiClient});

  @override
  Future<List<FolderEntity>> getFolders() async {
    final dynamic response = await apiClient.get(ApiEndpoints.folders);

    final dynamic body = _extractResponseBody(response);

    debugPrint('FOLDER API RESPONSE: $body');

    final List<dynamic> folderItems = _extractFolderList(body);

    return folderItems
        .whereType<Map>()
        .map((Map<dynamic, dynamic> item) {
          return FolderEntity.fromJson(_convertMap(item));
        })
        .where((FolderEntity folder) {
          return folder.id > 0;
        })
        .toList(growable: false);
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
      throw ArgumentError('Folder name is required.');
    }

    final dynamic response = await apiClient.post(
      ApiEndpoints.saveFolder,
      body: <String, dynamic>{
        'id': id,
        'name': cleanName,
        'iconName': iconName.trim().isEmpty ? 'folder' : iconName.trim(),
        'colorValue': colorValue.trim().isEmpty ? '#2196F3' : colorValue.trim(),
        'sortOrder': sortOrder,
      },
    );

    _validateApiResponse(_extractResponseBody(response));
  }

  @override
  Future<void> deleteOrRestoreFolder({
    required int id,
    required bool isDelete,
  }) async {
    if (id <= 0) {
      throw ArgumentError.value(
        id,
        'id',
        'Folder ID must be greater than zero.',
      );
    }

    final dynamic response = await apiClient.post(
      ApiEndpoints.deleteRestoreFolder,
      body: <String, dynamic>{'id': id, 'isDelete': isDelete},
    );

    final dynamic body = _extractResponseBody(response);

    debugPrint('DELETE/RESTORE FOLDER RESPONSE: $body');

    _validateApiResponse(body);
  }

  dynamic _extractResponseBody(dynamic response) {
    if (response == null) {
      return null;
    }

    if (response is Map ||
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

  List<dynamic> _extractFolderList(dynamic response) {
    if (response is List) {
      return response;
    }

    if (response is! Map) {
      return <dynamic>[];
    }

    final Map<String, dynamic> root = _convertMap(response);

    final dynamic data = _readIgnoreCase(root, 'data');

    if (data is List) {
      return data;
    }

    if (data is Map) {
      final Map<String, dynamic> dataMap = _convertMap(data);

      final dynamic folders = _firstValue(dataMap, const <String>[
        'folder',
        'folders',
        'items',
        'list',
        'rows',
      ]);

      if (folders is List) {
        return folders;
      }
    }

    final dynamic folders = _firstValue(root, const <String>[
      'folder',
      'folders',
      'items',
      'list',
      'rows',
    ]);

    if (folders is List) {
      return folders;
    }

    return <dynamic>[];
  }

  void _validateApiResponse(dynamic response) {
    if (response == null || response is! Map) {
      return;
    }

    final Map<String, dynamic> map = _convertMap(response);

    final dynamic codeValue = _readIgnoreCase(map, 'code');

    if (codeValue == null) {
      return;
    }

    final int code = int.tryParse(codeValue.toString()) ?? 0;

    final bool success =
        code == 0 || code == 200 || (code >= 200 && code < 300);

    if (success) {
      return;
    }

    final String message =
        _readIgnoreCase(map, 'message')?.toString() ??
        'The folder request failed.';

    throw StateError(message);
  }

  Map<String, dynamic> _convertMap(Map<dynamic, dynamic> map) {
    return map.map((dynamic key, dynamic value) {
      return MapEntry<String, dynamic>(key.toString(), value);
    });
  }

  dynamic _readIgnoreCase(Map<String, dynamic> map, String key) {
    final String wanted = key.toLowerCase();

    for (final MapEntry<String, dynamic> entry in map.entries) {
      if (entry.key.toLowerCase() == wanted) {
        return entry.value;
      }
    }

    return null;
  }

  dynamic _firstValue(Map<String, dynamic> map, List<String> keys) {
    for (final String key in keys) {
      final dynamic value = _readIgnoreCase(map, key);

      if (value != null) {
        return value;
      }
    }

    return null;
  }
}
