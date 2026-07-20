import 'package:flutter/foundation.dart';
import 'package:note_app/feature/folders/domain/repositories/folder_repository_impl.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/folder_entity.dart';

class FolderRepositoryImpl implements FolderRepository {
  final ApiClient apiClient;

  const FolderRepositoryImpl({required this.apiClient});

  @override
  Future<List<FolderEntity>> getFolders() async {
    final dynamic response = await apiClient.get(ApiEndpoints.folders);

    final dynamic body = _extractResponseBody(response);

    debugPrint('FOLDER API RESPONSE: $body');

    final List<dynamic> items = _extractFolderList(body);

    return items
        .whereType<Map>()
        .map((Map<dynamic, dynamic> item) {
          return FolderEntity.fromJson(
            item.map((dynamic key, dynamic value) {
              return MapEntry<String, dynamic>(key.toString(), value);
            }),
          );
        })
        .where((FolderEntity folder) => folder.id > 0)
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
    await apiClient.post(
      ApiEndpoints.saveFolder,
      body: <String, dynamic>{
        'id': id,
        'name': name.trim(),
        'iconName': iconName.trim(),
        'colorValue': colorValue.trim(),
        'sortOrder': sortOrder,
      },
    );
  }

  @override
  Future<void> deleteOrRestoreFolder({
    required int id,
    required bool isDelete,
  }) async {
    await apiClient.post(
      ApiEndpoints.deleteRestoreFolder,
      body: <String, dynamic>{'id': id, 'isDelete': isDelete},
    );
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

    final Map<String, dynamic> root = response.map((
      dynamic key,
      dynamic value,
    ) {
      return MapEntry<String, dynamic>(key.toString(), value);
    });

    final dynamic data = _readIgnoreCase(root, 'data');

    if (data is List) {
      return data;
    }

    if (data is Map) {
      final Map<String, dynamic> dataMap = data.map((
        dynamic key,
        dynamic value,
      ) {
        return MapEntry<String, dynamic>(key.toString(), value);
      });

      final dynamic folders = _firstValue(dataMap, const <String>[
        'folders',
        'folder',
        'items',
        'list',
        'rows',
        'records',
      ]);

      if (folders is List) {
        return folders;
      }
    }

    final dynamic folders = _firstValue(root, const <String>[
      'folders',
      'folder',
      'items',
      'list',
      'rows',
      'records',
    ]);

    if (folders is List) {
      return folders;
    }

    return <dynamic>[];
  }

  dynamic _readIgnoreCase(Map<String, dynamic> map, String key) {
    final String wantedKey = key.toLowerCase();

    for (final MapEntry<String, dynamic> entry in map.entries) {
      if (entry.key.toLowerCase() == wantedKey) {
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
