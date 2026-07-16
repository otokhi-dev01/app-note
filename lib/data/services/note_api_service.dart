import 'dart:convert';

import 'package:get/get.dart';

import '../../core/constants/api_config.dart';
import '../models/note_model.dart';
import 'auth_service.dart';

class NoteApiService {
  NoteApiService(
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

  Future<List<NoteModel>> getNotes({bool includeDeleted = false}) async {
    final response = await _client.get<dynamic>(
      ApiConfig.notesUrl,
      headers: _headers,
      query: includeDeleted
          ? const {
              'includeDeleted': true,
              'include_deleted': true,
              'withDeleted': true,
            }
          : null,
    );
    _ensureSuccess(response, 'load notes');
    final notes = _extractList(
      response.body,
    ).map(_noteFromJson).whereType<NoteModel>().toList(growable: false);
    return includeDeleted
        ? notes
        : notes.where((note) => !note.isDeleted).toList(growable: false);
  }

  Future<NoteModel?> getNote(int id) async {
    final response = await _client.get<dynamic>(
      ApiConfig.noteUrl(id),
      headers: _headers,
    );
    _ensureSuccess(response, 'load the note');
    final json = _extractObject(response.body);
    return json == null ? null : _noteFromJson(json);
  }

  Future<NoteModel> saveContent(NoteModel note) async {
    final body = _contentPayload(note);
    final response = await _client.post<dynamic>(
      ApiConfig.saveNoteContentUrl,
      body,
      headers: _headers,
    );
    _ensureSuccess(response, 'save note content');

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
    final body = <String, dynamic>{
      'id': note.id,
      'noteId': note.id,
      'note_id': note.id,
      'state': state,
      'stateName': state,
      'state_name': state,
      'field': switch (state) {
        'deleted' => 'isDeleted',
        'pinned' => 'isPinned',
        'locked' => 'isLocked',
        'folder' => 'folderId',
        _ => state,
      },
      'action': switch (state) {
        'deleted' => value == true ? 'delete' : 'restore',
        'pinned' => value == true ? 'pin' : 'unpin',
        'locked' => value == true ? 'lock' : 'unlock',
        'folder' => 'move',
        _ => state,
      },
      'value': value,
      'isDeleted': note.isDeleted,
      'is_deleted': note.isDeleted,
      'deleted': note.isDeleted,
      'isPinned': note.isPinned,
      'is_pinned': note.isPinned,
      'pinned': note.isPinned,
      'isLocked': note.isLocked,
      'is_locked': note.isLocked,
      'locked': note.isLocked,
      'folderId': note.folderId,
      'folder_id': note.folderId,
      'deletedAt': note.deletedAt?.toUtc().toIso8601String(),
      'deleted_at': note.deletedAt?.toUtc().toIso8601String(),
      'updatedAt': note.updatedAt.toUtc().toIso8601String(),
      'updated_at': note.updatedAt.toUtc().toIso8601String(),
    };
    final response = await _client.post<dynamic>(
      ApiConfig.updateNoteStateUrl,
      body,
      headers: _headers,
    );
    _ensureSuccess(response, 'update note state');
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
    throw NoteApiException(
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
    for (final key in const ['data', 'result', 'items', 'notes', 'records']) {
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
    return _looksLikeNote(map) ? [map] : const [];
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

  int? _extractResourceId(dynamic value) {
    final map = _asMap(_decode(value));
    if (map == null) return null;
    final id = _int(map['id'] ?? map['noteId'] ?? map['note_id'] ?? map['Id']);
    if (id != null) return id;
    for (final key in const ['data', 'result', 'note', 'item', 'record']) {
      final nestedId = _extractResourceId(map[key]);
      if (nestedId != null) return nestedId;
    }
    return null;
  }

  NoteModel? _noteFromJson(Map<String, dynamic> json, {NoteModel? fallback}) {
    final rawId = json['id'] ?? json['noteId'] ?? json['note_id'] ?? json['Id'];
    final id = _int(rawId) ?? fallback?.id;
    if (id == null) return null;

    final title =
        (json['title'] ??
                json['name'] ??
                json['noteTitle'] ??
                fallback?.title ??
                '')
            .toString();
    final content =
        (json['content'] ??
                json['noteContent'] ??
                json['note_content'] ??
                json['body'] ??
                json['text'] ??
                fallback?.content ??
                '')
            .toString();
    final rawCreatedAt =
        json['createdAt'] ?? json['created_at'] ?? json['dateCreated'];
    final rawUpdatedAt =
        json['updatedAt'] ??
        json['updated_at'] ??
        json['modifiedAt'] ??
        json['modified_at'];
    final createdAt =
        _date(rawCreatedAt) ?? fallback?.createdAt ?? _stableFallbackDate;
    final updatedAt = _date(rawUpdatedAt) ?? fallback?.updatedAt ?? createdAt;
    final rawDeletedAt = json['deletedAt'] ?? json['deleted_at'];
    final folderValue =
        json['folderId'] ?? json['folder_id'] ?? _asMap(json['folder'])?['id'];

    return NoteModel(
      id: id,
      title: title,
      content: content,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isDeleted:
          _bool(json['isDeleted'] ?? json['is_deleted'] ?? json['deleted']) ||
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
      folderId: _int(folderValue) ?? fallback?.folderId,
      isPinned: _hasAnyKey(json, const ['isPinned', 'is_pinned', 'pinned'])
          ? _bool(json['isPinned'] ?? json['is_pinned'] ?? json['pinned'])
          : fallback?.isPinned ?? false,
      isLocked: _hasAnyKey(json, const ['isLocked', 'is_locked', 'locked'])
          ? _bool(json['isLocked'] ?? json['is_locked'] ?? json['locked'])
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
      const ['id', 'noteId', 'note_id', 'Id'].contains,
    );
    final hasContent = value.keys.any(
      const [
        'title',
        'name',
        'content',
        'noteContent',
        'note_content',
        'body',
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

class NoteApiException implements Exception {
  const NoteApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
