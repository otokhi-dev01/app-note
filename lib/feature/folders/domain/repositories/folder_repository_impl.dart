import 'dart:convert';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/folder_entity.dart';
import 'folder_repository.dart';

class FolderRepositoryImpl implements FolderRepository {
  final ApiClient apiClient;

  const FolderRepositoryImpl({
    required this.apiClient,
  });

  @override
  Future<List<FolderEntity>> getFolders() async {
    final dynamic response = await apiClient.get(
      ApiEndpoints.folders,
    );

    final dynamic responseBody = _extractResponseBody(response);
    final List<dynamic> items = _extractFolderList(responseBody);

    return items
        .whereType<Map>()
        .map((Map<dynamic, dynamic> item) {
      return _folderFromJson(
        Map<String, dynamic>.from(item),
      );
    })
        .where((FolderEntity folder) => folder.id > 0)
        .toList(growable: false);
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

    await apiClient.post(
      ApiEndpoints.folderDeleteRestore,
      body: <String, dynamic>{
        'id': id,
        'isDelete': isDelete,
      },
    );
  }

  dynamic _extractResponseBody(dynamic response) {
    if (response == null) {
      throw StateError('The server returned an empty response.');
    }

    if (response is Map ||
        response is List ||
        response is String ||
        response is num ||
        response is bool) {
      return response;
    }

    try {
      final dynamic data = (response as dynamic).data;

      if (data != null) {
        return data;
      }
    } catch (_) {
      // ApiClient may already return response.data.
    }

    return response;
  }

  List<dynamic> _extractFolderList(dynamic response) {
    dynamic value = response;

    if (value is String) {
      final String text = value.trim();

      if (text.isEmpty) {
        return <dynamic>[];
      }

      value = jsonDecode(text);
    }

    if (value is List) {
      return value;
    }

    if (value is! Map) {
      throw StateError(
        'The folder API returned an invalid response.',
      );
    }

    final Map<String, dynamic> root =
    Map<String, dynamic>.from(value);

    final dynamic data = root['data'];

    if (data is List) {
      return data;
    }

    if (data is Map) {
      final Map<String, dynamic> dataMap =
      Map<String, dynamic>.from(data);

      // Important: your API uses data.folder.
      final dynamic folderList =
          dataMap['folder'] ??
              dataMap['folders'] ??
              dataMap['items'] ??
              dataMap['list'] ??
              dataMap['result'];

      if (folderList is List) {
        return folderList;
      }
    }

    final dynamic rootList =
        root['folder'] ??
            root['folders'] ??
            root['items'] ??
            root['list'] ??
            root['result'];

    if (rootList is List) {
      return rootList;
    }

    return <dynamic>[];


  }

  FolderEntity _folderFromJson(
      Map<String, dynamic> json,
      ) {
    return FolderEntity(
      id: _toInt(
        json['FolderId'] ??
            json['folderId'] ??
            json['Id'] ??
            json['id'],
      ),
      name:
      json['FolderName']?.toString() ??
          json['folderName']?.toString() ??
          json['Name']?.toString() ??
          json['name']?.toString() ??
          '',
      iconName:
      json['IconName']?.toString() ??
          json['iconName']?.toString() ??
          'folder',
      colorValue:
      json['ColorValue']?.toString() ??
          json['colorValue']?.toString() ??
          '#2196F3',
      sortOrder: _toInt(
        json['SortOrder'] ??
            json['sortOrder'],
      ),
      noteCount: _toInt(
        json['NoteCount'] ??
            json['noteCount'],
      ),

      // This determines whether it goes to the recycle bin.
      deletedAt: _toDateTime(
        json['DeletedAt'] ??
            json['deletedAt'],
      ),
    );
  }

  int _toInt(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  DateTime? _toDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    final String text = value.toString().trim();

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }

    return DateTime.tryParse(text);
  }

  @override
  Future<void> saveFolder({required int id, required String name, required String iconName, required String colorValue, required int sortOrder}) {
    // TODO: implement saveFolder
    throw UnimplementedError();
  }
}