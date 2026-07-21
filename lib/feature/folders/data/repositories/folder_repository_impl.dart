import 'package:note_app/core/network/api_client.dart';
import 'package:note_app/core/network/api_endpoints.dart';
import 'package:note_app/core/network/api_exception.dart';
import 'package:note_app/feature/folders/domain/entities/folder_entity.dart';
import 'package:note_app/feature/folders/domain/repositories/folder_repository.dart';

class FolderRepositoryImpl implements FolderRepository {
  final ApiClient apiClient;

  const FolderRepositoryImpl({required this.apiClient});

  @override
  Future<List<FolderEntity>> getFolders() async {
    final dynamic response = await apiClient.get(
      ApiEndpoints.folders,
      requiresAuth: true,
      useAuthBaseUrl: false,
    );

    _validateResponse(response);

    final List<dynamic> items = <dynamic>[..._extractFolders(response)];

    final Map<int, FolderEntity> foldersById = <int, FolderEntity>{};

    for (final FolderEntity folder
        in items
            .whereType<Map>()
            .map((Map<dynamic, dynamic> item) {
              return FolderEntity.fromJson(
                item.map((dynamic key, dynamic value) {
                  return MapEntry<String, dynamic>(key.toString(), value);
                }),
              );
            })
            .where((FolderEntity folder) {
              return folder.id > 0;
            })) {
      final FolderEntity? current = foldersById[folder.id];

      if (current == null || folder.isDeleted || !current.isDeleted) {
        foldersById[folder.id] = folder;
      }
    }

    return foldersById.values.toList(growable: false);
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
      throw const ApiException(message: 'Folder name is required.');
    }

    final dynamic response = await apiClient.post(
      ApiEndpoints.saveFolder,
      requiresAuth: true,
      useAuthBaseUrl: false,
      body: <String, dynamic>{
        'id': id,
        'name': cleanName,
        'iconName': iconName.trim().isEmpty ? 'folder' : iconName.trim(),
        'colorValue': colorValue.trim().isEmpty ? '#2196F3' : colorValue.trim(),
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
      throw const ApiException(message: 'Invalid folder ID.');
    }

    final dynamic response = await _sendFolderOperation(
      id: id,
      isDeleteValue: isDelete,
    );

    if (!_operationWasIgnored(response, requestedDelete: isDelete)) {
      return;
    }

    /*
     * Older deployed API versions use `isDeleted`, `deleted`, `restore`, or
     * `action` instead of `isDelete`. Retry once with those known aliases
     * instead of treating this HTTP/code 200 no-op as a successful delete.
     */
    final dynamic compatibilityResponse = await _sendFolderOperation(
      id: id,
      isDeleteValue: isDelete,
      includeIsDelete: false,
      compatibilityDeleteValue: isDelete,
    );

    if (_operationWasIgnored(
      compatibilityResponse,
      requestedDelete: isDelete,
    )) {
      throw ApiException(
        message: _folderOperationFailureMessage(
          compatibilityResponse,
          requestedDelete: isDelete,
        ),
        responseData: compatibilityResponse,
      );
    }
  }

  Future<dynamic> _sendFolderOperation({
    required int id,
    required bool isDeleteValue,
    bool includeIsDelete = true,
    bool? compatibilityDeleteValue,
  }) async {
    final dynamic response = await apiClient.post(
      ApiEndpoints.deleteRestoreFolder,
      requiresAuth: true,
      useAuthBaseUrl: false,
      body: <String, dynamic>{
        'id': id,
        if (includeIsDelete) 'isDelete': isDeleteValue,
        if (compatibilityDeleteValue != null) ...<String, dynamic>{
          'folderId': id,
          'folder_id': id,
          'isDeleted': compatibilityDeleteValue,
          'is_deleted': compatibilityDeleteValue,
          'deleted': compatibilityDeleteValue,
          'restore': !compatibilityDeleteValue,
          'action': compatibilityDeleteValue ? 'delete' : 'restore',
        },
      },
    );

    _validateResponse(response);

    return response;
  }

  bool _operationWasIgnored(dynamic response, {required bool requestedDelete}) {
    final String message = _responseMessage(response).toLowerCase();

    if (message.isEmpty) {
      return false;
    }

    if (requestedDelete) {
      return message.contains('already active') ||
          message.contains('already restored');
    }

    return message.contains('already deleted') ||
        message.contains('already in trash') ||
        message.contains('already inactive');
  }

  String _folderOperationFailureMessage(
    dynamic response, {
    required bool requestedDelete,
  }) {
    final String serverMessage = _responseMessage(response);
    final String action = requestedDelete ? 'delete' : 'restore';

    if (serverMessage.isEmpty) {
      return 'The server did not $action the folder.';
    }

    return 'The server did not $action the folder: $serverMessage';
  }

  String _responseMessage(dynamic response) {
    final dynamic body = _unwrapResponse(response);

    if (body is! Map) {
      return '';
    }

    final Map<String, dynamic> map = _convertMap(body);
    final dynamic message = _readValue(map, const <String>[
      'message',
      'detail',
      'status',
    ]);

    return message?.toString().trim() ?? '';
  }

  List<dynamic> _extractFolders(dynamic response) {
    final dynamic body = _unwrapResponse(response);

    if (body is List) {
      return body;
    }

    if (body is! Map) {
      return <dynamic>[];
    }

    final Map<String, dynamic> root = body.map((dynamic key, dynamic value) {
      return MapEntry<String, dynamic>(key.toString(), value);
    });

    final dynamic data = _readValue(root, const <String>['data']);

    if (data is List) {
      return data;
    }

    if (data is Map) {
      final List<dynamic>? folders = _extractFolderCollections(
        _convertMap(data),
      );

      if (folders != null) {
        return folders;
      }
    }

    return _extractFolderCollections(root) ?? <dynamic>[];
  }

  /// Extracts both collections returned by the folder endpoint.
  ///
  /// The current API returns active folders in `folder` and deleted folders
  /// in `trash`. Trash items are marked before parsing so HomeController can
  /// classify them even when the server leaves `DeletedAt` empty.
  List<dynamic>? _extractFolderCollections(Map<String, dynamic> map) {
    final dynamic activeFolders = _readValue(map, const <String>[
      'folder',
      'folders',
      'items',
      'rows',
      'records',
    ]);
    final dynamic deletedFolders = _readValue(map, const <String>[
      'trash',
      'deleted',
      'deletedFolders',
    ]);

    if (activeFolders is! List && deletedFolders is! List) {
      return null;
    }

    return <dynamic>[
      if (activeFolders is List) ...activeFolders,
      if (deletedFolders is List) ...deletedFolders.map(_markAsTrashItem),
    ];
  }

  dynamic _markAsTrashItem(dynamic item) {
    if (item is! Map) {
      return item;
    }

    return <String, dynamic>{..._convertMap(item), 'IsInTrash': true};
  }

  Map<String, dynamic> _convertMap(Map<dynamic, dynamic> map) {
    return map.map(
      (dynamic key, dynamic value) =>
          MapEntry<String, dynamic>(key.toString(), value),
    );
  }

  void _validateResponse(dynamic response) {
    final dynamic body = _unwrapResponse(response);

    if (body == null) {
      throw const ApiException(
        message: 'The server returned an empty response.',
      );
    }

    if (body is! Map) {
      return;
    }

    final Map<String, dynamic> map = body.map((dynamic key, dynamic value) {
      return MapEntry<String, dynamic>(key.toString(), value);
    });

    final int? code = _toInt(
      _readValue(map, const <String>['code', 'statusCode', 'status_code']),
    );

    final bool? success = _toBool(
      _readValue(map, const <String>['success', 'isSuccess', 'succeeded']),
    );

    if (success == false) {
      throw ApiException(
        message: _messageFromMap(map),
        statusCode: code,
        responseData: body,
      );
    }

    if (code != null && code != 0 && (code < 200 || code >= 300)) {
      throw ApiException(
        message: _messageFromMap(map),
        statusCode: code,
        responseData: body,
      );
    }
  }

  dynamic _unwrapResponse(dynamic response) {
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

  dynamic _readValue(Map<String, dynamic> map, List<String> keys) {
    for (final String key in keys) {
      for (final MapEntry<String, dynamic> entry in map.entries) {
        if (entry.key.toLowerCase() == key.toLowerCase()) {
          return entry.value;
        }
      }
    }

    return null;
  }

  String _messageFromMap(Map<String, dynamic> map) {
    final dynamic message = _readValue(map, const <String>[
      'message',
      'error',
      'errorMessage',
      'detail',
    ]);

    final String text = message?.toString().trim() ?? '';

    return text.isEmpty ? 'The folder request failed.' : text;
  }

  int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '');
  }

  bool? _toBool(dynamic value) {
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
