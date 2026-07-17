import 'dart:convert';

import 'package:get/get.dart';

import 'package:notes/core/network/api_endpoints.dart';
import 'package:notes/core/network/api_failure.dart';
import 'package:notes/features/auth/domain/repositories/auth_repository.dart';
import 'package:notes/features/notes/data/models/folder_model.dart';

class FolderApiService {
  FolderApiService(
    this._authService, {
    GetConnect? client,
    String? Function()? tokenProvider,
  }) : _client = client ?? GetConnect(),
       _tokenProvider = tokenProvider {
    _client.timeout = const Duration(seconds: 20);
  }

  final AuthRepository _authService;
  final GetConnect _client;
  final String? Function()? _tokenProvider;

  Future<List<FolderModel>> getFolders() async {
    final response = await _request(
      () => _client.get<dynamic>(ApiEndpoints.folders, headers: _headers),
      'load folders',
    );
    _ensureSuccess(response, 'load folders');
    _ensureApplicationSuccess(response.body, 'load folders');
    if (response.statusCode == 204) return const [];

    final values = _extractList(response.body);
    final folders = <FolderModel>[];
    for (final json in values) {
      final folder = _folderFromJson(json);
      if (folder == null) {
        throw const FolderApiException(
          'The folders API returned an invalid folder record.',
        );
      }
      folders.add(folder);
    }
    return folders;
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
    final response = await _request(
      () => _client.post<dynamic>(
        ApiEndpoints.saveFolder,
        jsonEncode(body),
        headers: _headers,
      ),
      'save the folder',
    );
    _ensureSuccess(response, 'save the folder');
    _ensureApplicationSuccess(response.body, 'save the folder');

    final json = _extractObject(response.body);
    final folder = json == null ? null : _folderFromJson(json);
    if (folder != null) return folder;

    // Some save endpoints return only a success envelope. Refreshing the list
    // gives the repository the server-assigned identifier in that case.
    late final List<FolderModel> folders;
    try {
      folders = await getFolders();
    } on FolderApiException catch (error) {
      if (!error.isRetryable) rethrow;
      if (id != null) rethrow;
      // The POST may already have committed. Treat a failed confirmation as
      // ambiguous instead of falling back to another local create.
      throw FolderApiException(
        'The folder may have been saved, but the server confirmation failed.',
        kind: ApiFailureKind.protocol,
        statusCode: error.statusCode,
        cause: error,
      );
    }
    final refreshed = folders.firstWhereOrNull(
      (item) => item.name.toLowerCase() == normalizedName.toLowerCase(),
    );
    if (refreshed != null) return refreshed;
    throw const FolderApiException(
      'The folder was saved, but the server did not return its identifier.',
    );
  }

  Future<void> setFolderDeleted(int id, {required bool deleted}) async {
    // Keep delete-restore payload strict/minimal to match backend validation.
    final response = await _request(
      () => _client.post<dynamic>(
        ApiEndpoints.deleteRestoreFolder,
        jsonEncode(<String, dynamic>{
          'id': id,
          'deleted': deleted,
          'action': deleted ? 'delete' : 'restore',
          'restore': !deleted,
        }),
        headers: _headers,
      ),
      deleted ? 'delete the folder' : 'restore the folder',
    );
    _ensureSuccess(
      response,
      deleted ? 'delete the folder' : 'restore the folder',
    );
    _ensureApplicationSuccess(
      response.body,
      deleted ? 'delete the folder' : 'restore the folder',
    );
  }

  Map<String, String> get _headers {
    final token = (_tokenProvider?.call() ?? _authService.user?.token)?.trim();
    if (token == null || token.isEmpty) {
      throw const FolderApiException(
        'An authenticated session is required for folder sync.',
        kind: ApiFailureKind.http,
        statusCode: 401,
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
    final statusCode = response.statusCode;

    final rawBody = response.body;
    final raw = rawBody is String
        ? rawBody
        : rawBody == null
        ? null
        : const JsonEncoder().convert(rawBody);

    throw FolderApiException(
      '${message ?? 'Unable to $operation'} (${statusCode ?? 'network error'}). '
      'Response: ${raw ?? '<empty>'}',
      statusCode: statusCode,
      kind: statusCode == null || statusCode <= 0
          ? ApiFailureKind.transport
          : ApiFailureKind.http,
    );
  }

  Future<Response<dynamic>> _request(
    Future<Response<dynamic>> Function() request,
    String operation,
  ) async {
    try {
      return await request();
    } on FolderApiException {
      rethrow;
    } on FormatException catch (error) {
      throw FolderApiException(
        error.message,
        kind: ApiFailureKind.protocol,
        cause: error,
      );
    } on Exception catch (error) {
      throw FolderApiException(
        'Unable to $operation because the server could not be reached.',
        kind: ApiFailureKind.transport,
        cause: error,
      );
    }
  }

  void _ensureApplicationSuccess(dynamic value, String operation) {
    final map = _asMap(_decode(value));
    if (map?['success'] != false) return;

    throw FolderApiException(
      _errorMessage(map) ?? 'The server could not $operation.',
    );
  }

  List<Map<String, dynamic>> _extractList(dynamic value) {
    final result = _tryExtractList(value);
    if (!result.found) {
      throw const FolderApiException(
        'The folders API returned an invalid folders response.',
      );
    }
    return result.values;
  }

  ({bool found, List<Map<String, dynamic>> values}) _tryExtractList(
    dynamic value,
  ) {
    final decoded = _decode(value);
    if (decoded is List) {
      return (found: true, values: _mapList(decoded));
    }
    final map = _asMap(decoded);
    if (map == null) return (found: false, values: const []);
    if (_looksLikeFolder(map)) return (found: true, values: [map]);

    for (final key in const ['data', 'result', 'items', 'folders', 'records']) {
      if (!map.containsKey(key)) continue;
      final nested = map[key];
      if (nested is List) {
        return (found: true, values: _mapList(nested));
      }
      final result = _tryExtractList(nested);
      if (result.found) return result;
    }
    return (found: false, values: const []);
  }

  List<Map<String, dynamic>> _mapList(List<dynamic> values) {
    final result = <Map<String, dynamic>>[];
    for (final value in values) {
      final map = _asMap(value);
      if (map == null) {
        throw const FolderApiException(
          'The folders API returned an invalid folder record.',
        );
      }
      result.add(map);
    }
    return result;
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

class FolderApiException extends ApiFailure {
  const FolderApiException(
    String message, {
    ApiFailureKind kind = ApiFailureKind.protocol,
    int? statusCode,
    Object? cause,
  }) : super(message, kind: kind, statusCode: statusCode, cause: cause);
}
