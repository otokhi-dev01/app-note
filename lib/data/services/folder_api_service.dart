import 'dart:convert';
import 'package:get/get.dart';
import '../../core/constants/api_config.dart';
import '../models/folder_model.dart';
import 'auth_service.dart';

class FolderApiService {
  FolderApiService(
    this._authService, {
    GetConnect? client,
    String? Function()? tokenProvider,
  }) : _client = client ?? GetConnect(),
       _tokenProvider = tokenProvider {
    _client.timeout = const Duration(seconds: 20);
  }

  final AuthService _authService;
  final GetConnect _client;
  final String? Function()? _tokenProvider;

  Future<List<FolderModel>> getFolders() async {
    final response = await _client.get<dynamic>(
      ApiConfig.foldersUrl,
      headers: _headers,
    );
    _ensureSuccess(response, 'load folders');

    final values = _extractList(response.body);
    return values
        .map(_folderFromJson)
        .whereType<FolderModel>()
        .toList(growable: false);
  }

  Future<FolderModel?> saveFolder({int? id, required String name}) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw const FolderApiException('Folder name cannot be empty.');
    }

    final body = <String, dynamic>{
      if (id != null) ...{'id': id, 'folderId': id, 'folder_id': id},
      'name': normalizedName,
      'folderName': normalizedName,
      'folder_name': normalizedName,
    };
    final response = await _client.post<dynamic>(
      ApiConfig.saveFolderUrl,
      body,
      headers: _headers,
    );
    _ensureSuccess(response, 'save the folder');

    final json = _extractObject(response.body);
    final folder = json == null ? null : _folderFromJson(json);
    if (folder != null) return folder;

    // Some save endpoints return only a success envelope. Refreshing the list
    // gives the repository the server-assigned identifier in that case.
    final folders = await getFolders();
    return folders.firstWhereOrNull(
      (item) => item.name.toLowerCase() == normalizedName.toLowerCase(),
    );
  }

  Future<void> setFolderDeleted(int id, {required bool deleted}) async {
    final response = await _client
        .post<dynamic>(ApiConfig.deleteRestoreFolderUrl, <String, dynamic>{
          'id': id,
          'folderId': id,
          'folder_id': id,
          'isDeleted': deleted,
          'is_deleted': deleted,
          'deleted': deleted,
          'restore': !deleted,
          'action': deleted ? 'delete' : 'restore',
        }, headers: _headers);
    _ensureSuccess(
      response,
      deleted ? 'delete the folder' : 'restore the folder',
    );
  }

  Map<String, String> get _headers {
    final token = (_tokenProvider?.call() ?? _authService.user?.token)?.trim();
    if (token == null || token.isEmpty) {
      throw const FolderApiException(
        'An authenticated session is required for folder sync.',
      );
    }
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  void _ensureSuccess(Response<dynamic> response, String operation) {
    if (response.isOk) return;
    final message = _errorMessage(response.body);
    throw FolderApiException(
      message ??
          'Unable to $operation (${response.statusCode ?? 'network error'}).',
      statusCode: response.statusCode,
    );
  }

  List<Map<String, dynamic>> _extractList(dynamic value) {
    final decoded = _decode(value);
    if (decoded is List) {
      return decoded.map(_asMap).whereType<Map<String, dynamic>>().toList();
    }
    final map = _asMap(decoded);
    if (map == null) return const [];

    for (final key in const ['data', 'result', 'items', 'folders', 'records']) {
      final nested = map[key];
      if (nested is List) {
        return nested.map(_asMap).whereType<Map<String, dynamic>>().toList();
      }
      final nestedMap = _asMap(nested);
      if (nestedMap != null) {
        final result = _extractList(nestedMap);
        if (result.isNotEmpty) return result;
      }
    }
    return _looksLikeFolder(map) ? [map] : const [];
  }

  Map<String, dynamic>? _extractObject(dynamic value) {
    final map = _asMap(_decode(value));
    if (map == null) return null;
    if (_looksLikeFolder(map)) return map;
    for (final key in const ['data', 'result', 'folder', 'item', 'record']) {
      final nested = _asMap(map[key]);
      if (nested == null) continue;
      final result = _extractObject(nested);
      if (result != null) return result;
    }
    return null;
  }

  FolderModel? _folderFromJson(Map<String, dynamic> json) {
    final rawId =
        json['id'] ?? json['folderId'] ?? json['folder_id'] ?? json['Id'];
    final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
    if (id == null) return null;

    final name =
        (json['name'] ??
                json['folderName'] ??
                json['folder_name'] ??
                json['title'] ??
                '')
            .toString()
            .trim();
    if (name.isEmpty) return null;

    final rawCreatedAt =
        json['createdAt'] ??
        json['created_at'] ??
        json['dateCreated'] ??
        json['createdDate'];
    final createdAt = DateTime.tryParse(
      rawCreatedAt?.toString() ?? '',
    )?.toLocal();
    return FolderModel(
      id: id,
      name: name,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  bool _looksLikeFolder(Map<String, dynamic> value) {
    final hasId = value.keys.any(
      const ['id', 'folderId', 'folder_id', 'Id'].contains,
    );
    final hasName = value.keys.any(
      const ['name', 'folderName', 'folder_name', 'title'].contains,
    );
    return hasId && hasName;
  }

  String? _errorMessage(dynamic value) {
    final map = _asMap(_decode(value));
    if (map == null) return null;
    final message =
        map['message'] ?? map['error'] ?? map['detail'] ?? map['title'];
    if (message is String && message.trim().isNotEmpty) return message.trim();
    return null;
  }

  dynamic _decode(dynamic value) {
    if (value is! String || value.trim().isEmpty) return value;
    try {
      return jsonDecode(value);
    } on FormatException {
      return value;
    }
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return null;
  }
}

class FolderApiException implements Exception {
  const FolderApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
