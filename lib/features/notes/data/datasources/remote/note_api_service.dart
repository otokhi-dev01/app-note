import 'dart:convert';

import 'package:get/get.dart';

import 'package:notes/core/network/api_endpoints.dart';
import 'package:notes/core/network/api_failure.dart';
import 'package:notes/features/auth/domain/repositories/auth_repository.dart';
import 'package:notes/features/notes/data/models/note_model.dart';

class NoteApiService {
  NoteApiService(
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

  Future<List<NoteModel>> getNotes({bool includeDeleted = false}) async {
    final response = await _request(
      () => _client.get<dynamic>(
        ApiEndpoints.notes,
        headers: _headers,
        query: includeDeleted
            ? const {
                'includeDeleted': true,
                'include_deleted': true,
                'withDeleted': true,
              }
            : null,
      ),
      'load notes',
    );
    _ensureSuccess(response, 'load notes');
    _ensureApplicationSuccess(response.body, 'load notes');
    if (response.statusCode == 204) return const [];

    final notes = <NoteModel>[];
    for (final json in _extractList(response.body)) {
      final note = _noteFromJson(json);
      if (note == null) {
        throw const NoteApiException(
          'The notes API returned an invalid note record.',
        );
      }
      notes.add(note);
    }
    return includeDeleted
        ? notes
        : notes.where((note) => !note.isDeleted).toList(growable: false);
  }

  Future<NoteModel?> getNote(int id) async {
    final response = await _request(
      () => _client.get<dynamic>(ApiEndpoints.note(id), headers: _headers),
      'load the note',
    );
    _ensureSuccess(response, 'load the note');
    _ensureApplicationSuccess(response.body, 'load the note');
    final json = _extractObject(response.body);
    if (json == null) {
      if (response.statusCode == 204 || _isExplicitEmptyObject(response.body)) {
        return null;
      }
      throw const NoteApiException(
        'The notes API returned an invalid note response.',
      );
    }
    final note = _noteFromJson(json);
    if (note == null) {
      throw const NoteApiException(
        'The notes API returned an invalid note record.',
      );
    }
    return note;
  }

  Future<NoteModel> saveContent(NoteModel note) async {
    final body = _contentPayload(note);
    final response = await _request(
      () => _client.post<dynamic>(
        ApiEndpoints.saveNoteContent,
        jsonEncode(body),
        headers: _headers,
      ),
      'save note content',
    );
    _ensureSuccess(response, 'save note content');
    _ensureApplicationSuccess(response.body, 'save note content');

    final json = _extractObject(response.body);
    final saved = json == null ? null : _noteFromJson(json, fallback: note);
    if (saved != null) return saved;
    final createdId = _extractResourceId(response.body);
    if (createdId != null && createdId > 0) {
      return note.copyWith(id: createdId);
    }
    if (note.id != null && note.id! > 0) {
      final refreshed = await getNote(note.id!);
      if (refreshed != null) return refreshed;
    }

    // A create must return its server identifier. Guessing the new resource by
    // matching title/content is unsafe when two notes contain the same text.
    throw const NoteApiException(
      'The note was saved, but the server did not return its identifier.',
    );
  }

  Future<NoteModel?> updateState(
    NoteModel note, {
    required String state,
    required Object? value,
  }) async {
    if (note.id == null || note.id! <= 0) {
      throw const NoteApiException(
        'A synced note ID is required to update state.',
      );
    }
    // Keep update-state payload strict/minimal to match backend validation.
    // Sending many aliased field names can cause 400/protocol failures.
    final body = <String, dynamic>{
      'id': note.id,
      'state': state,
      'action': switch (state) {
        'deleted' => value == true ? 'delete' : 'restore',
        'pinned' => value == true ? 'pin' : 'unpin',
        'locked' => value == true ? 'lock' : 'unlock',
        'folder' => 'move',
        _ => value,
      },
      // Backend-specific value for the state/action.
      'value': value,
    };
    final response = await _request(
      () => _client.post<dynamic>(
        ApiEndpoints.updateNoteState,
        jsonEncode(body),
        headers: _headers,
      ),
      'update note state',
    );
    _ensureSuccess(response, 'update note state');
    _ensureApplicationSuccess(response.body, 'update note state');
    final json = _extractObject(response.body);
    final updated = json == null ? null : _noteFromJson(json, fallback: note);
    if (updated != null) return updated;

    // State endpoints often return only { success: true }. Refresh the
    // canonical resource so callers do not cache a guessed state.
    return getNote(note.id!);
  }

  Map<String, dynamic> _contentPayload(NoteModel note) {
    return <String, dynamic>{
      if (note.id != null && note.id! > 0) ...{
        'id': note.id,
        'noteId': note.id,
        'note_id': note.id,
      },
      'title': note.title,
      'name': note.title,
      'content': note.content,
      'noteContent': note.content,
      'note_content': note.content,
      'body': note.content,
      'folderId': note.folderId,
      'folder_id': note.folderId,
      // Local attachment paths are intentionally not sent. They are private
      // device paths, not uploaded media identifiers. A dedicated upload API
      // can add attachment IDs here when that contract is provided.
      'createdAt': note.createdAt.toUtc().toIso8601String(),
      'created_at': note.createdAt.toUtc().toIso8601String(),
      'updatedAt': note.updatedAt.toUtc().toIso8601String(),
      'updated_at': note.updatedAt.toUtc().toIso8601String(),
    };
  }

  Map<String, String> get _headers {
    final token = (_tokenProvider?.call() ?? _authService.user?.token)?.trim();
    if (token == null || token.isEmpty) {
      throw const NoteApiException(
        'An authenticated session is required for note sync.',
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

    throw NoteApiException(
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
    } on NoteApiException {
      rethrow;
    } on FormatException catch (error) {
      throw NoteApiException(
        error.message,
        kind: ApiFailureKind.protocol,
        cause: error,
      );
    } on Exception catch (error) {
      throw NoteApiException(
        'Unable to $operation because the server could not be reached.',
        kind: ApiFailureKind.transport,
        cause: error,
      );
    }
  }

  void _ensureApplicationSuccess(dynamic value, String operation) {
    final map = _asMap(_decode(value));
    if (map?['success'] != false) return;

    throw NoteApiException(
      _errorMessage(map) ?? 'The server could not $operation.',
    );
  }

  List<Map<String, dynamic>> _extractList(dynamic value) {
    final result = _tryExtractList(value);
    if (!result.found) {
      throw const NoteApiException(
        'The notes API returned an invalid notes response.',
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
    if (_looksLikeNote(map)) return (found: true, values: [map]);

    for (final key in const ['data', 'result', 'items', 'notes', 'note', 'records']) {
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
        throw const NoteApiException(
          'The notes API returned an invalid note record.',
        );
      }
      result.add(map);
    }
    return result;
  }

  Map<String, dynamic>? _extractObject(dynamic value) {
    final map = _asMap(_decode(value));
    if (map == null) return null;
    if (_looksLikeNote(map)) return map;
    for (final key in const ['data', 'result', 'note', 'item', 'record']) {
      final nested = _asMap(map[key]);
      if (nested == null) continue;
      final result = _extractObject(nested);
      if (result != null) return result;
    }
    return null;
  }

  bool _isExplicitEmptyObject(dynamic value) {
    final map = _asMap(_decode(value));
    if (map == null) return false;
    for (final key in const ['data', 'result', 'note', 'item', 'record']) {
      if (!map.containsKey(key)) continue;
      final nested = map[key];
      if (nested == null) return true;
      if (_isExplicitEmptyObject(nested)) return true;
    }
    return false;
  }

  int? _extractResourceId(dynamic value) {
    final map = _asMap(_decode(value));
    if (map == null) return null;
    final id = _int(map['id'] ?? map['noteId'] ?? map['note_id'] ?? map['Id'] ?? map['NoteId']);
    if (id != null) return id;
    for (final key in const ['data', 'result', 'note', 'item', 'record']) {
      final nestedId = _extractResourceId(map[key]);
      if (nestedId != null) return nestedId;
    }
    return null;
  }

  NoteModel? _noteFromJson(Map<String, dynamic> json, {NoteModel? fallback}) {
    final rawId = json['id'] ?? json['noteId'] ?? json['note_id'] ?? json['Id'] ?? json['NoteId'];
    final id = _int(rawId) ?? fallback?.id;
    if (id == null) return null;

    final title =
        (json['title'] ??
                json['name'] ??
                json['noteTitle'] ??
                json['Title'] ??
                json['NoteTitle'] ??
                fallback?.title ??
                '')
            .toString();
    final content =
        (json['content'] ??
                json['noteContent'] ??
                json['note_content'] ??
                json['body'] ??
                json['text'] ??
                json['Content'] ??
                json['NoteContent'] ??
                fallback?.content ??
                '')
            .toString();
    final rawCreatedAt =
        json['createdAt'] ?? json['created_at'] ?? json['dateCreated'] ?? json['CreatedAt'];
    final rawUpdatedAt =
        json['updatedAt'] ??
        json['updated_at'] ??
        json['modifiedAt'] ??
        json['modified_at'] ??
        json['UpdatedAt'];
    final createdAt =
        _date(rawCreatedAt) ?? fallback?.createdAt ?? _stableFallbackDate;
    final updatedAt = _date(rawUpdatedAt) ?? fallback?.updatedAt ?? createdAt;
    final rawDeletedAt = json['deletedAt'] ?? json['deleted_at'] ?? json['DeletedAt'];
    final folderValue =
        json['folderId'] ?? json['folder_id'] ?? json['FolderId'] ?? _asMap(json['folder'])?['id'];

    return NoteModel(
      id: id,
      title: title,
      content: content,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isDeleted:
          _bool(json['isDeleted'] ?? json['is_deleted'] ?? json['deleted'] ?? json['IsDeleted']) ||
          rawDeletedAt != null,
      deletedAt: _date(rawDeletedAt) ?? fallback?.deletedAt,
      imagePaths:
          _hasAnyKey(json, const [
            'imagePaths',
            'image_paths',
            'attachments',
            'images',
          ])
          ? _imagePaths(
              json['imagePaths'] ??
                  json['image_paths'] ??
                  json['attachments'] ??
                  json['images'],
            )
          : fallback?.imagePaths ?? const [],
      imageAnchors: fallback?.imageAnchors ?? const [],
      folderId: _int(folderValue) ?? fallback?.folderId,
      isPinned: _hasAnyKey(json, const ['isPinned', 'is_pinned', 'pinned', 'IsPinned'])
          ? _bool(json['isPinned'] ?? json['is_pinned'] ?? json['pinned'] ?? json['IsPinned'])
          : fallback?.isPinned ?? false,
      isLocked: _hasAnyKey(json, const ['isLocked', 'is_locked', 'locked', 'IsLocked'])
          ? _bool(json['isLocked'] ?? json['is_locked'] ?? json['locked'] ?? json['IsLocked'])
          : fallback?.isLocked ?? false,
    );
  }

  List<String> _imagePaths(dynamic value) {
    final decoded = _decode(value);
    if (decoded is List) {
      return decoded
          .map((item) {
            if (item is String) return item;
            final map = _asMap(item);
            return (map?['url'] ??
                    map?['path'] ??
                    map?['filePath'] ??
                    map?['file_path'])
                ?.toString();
          })
          .whereType<String>()
          .where((path) => path.trim().isNotEmpty)
          .toList(growable: false);
    }
    if (decoded is String && decoded.trim().isNotEmpty) {
      return decoded
          .split('|')
          .map((path) => path.trim())
          .where((path) => path.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }

  bool _looksLikeNote(Map<String, dynamic> value) {
    final hasId = value.keys.any(
      const ['id', 'noteId', 'note_id', 'Id', 'NoteId'].contains,
    );
    final hasContent = value.keys.any(
      const [
        'title',
        'name',
        'content',
        'noteContent',
        'note_content',
        'body',
        'Title',
        'Content',
        'NoteTitle',
        'NoteContent',
      ].contains,
    );
    return hasId && hasContent;
  }

  DateTime? _date(dynamic value) {
    if (value == null) return null;
    if (value is int) {
      final milliseconds = value < 100000000000 ? value * 1000 : value;
      return DateTime.fromMillisecondsSinceEpoch(milliseconds).toLocal();
    }
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  bool _bool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value?.toString().trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }

  int? _int(dynamic value) {
    if (value is int) return value;
    if (value is num && value.isFinite && value == value.roundToDouble()) {
      return value.toInt();
    }
    return int.tryParse(value?.toString().trim() ?? '');
  }

  bool _hasAnyKey(Map<String, dynamic> value, List<String> keys) {
    return keys.any(value.containsKey);
  }

  static final DateTime _stableFallbackDate =
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true).toLocal();

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

class NoteApiException extends ApiFailure {
  const NoteApiException(
    String message, {
    ApiFailureKind kind = ApiFailureKind.protocol,
    int? statusCode,
    Object? cause,
  }) : super(message, kind: kind, statusCode: statusCode, cause: cause);
}
