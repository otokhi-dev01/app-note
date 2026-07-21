import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_parser.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/repositories/note_state_field.dart';

class NoteRepositoryImpl implements NoteRepository {
  final ApiClient apiClient;

  const NoteRepositoryImpl({required this.apiClient});

  // ===========================================================================
  // GET NOTE LIST
  // GET /api/note
  // ===========================================================================

  @override
  Future<List<NoteEntity>> getNotes() async {
    final dynamic response = await apiClient.get(ApiEndpoints.notes);

    final dynamic responseBody = _decodedResponseBody(response);

    ApiParser.ensureSuccess(
      responseBody,
      fallbackMessage: 'Unable to load notes.',
    );

    final List<dynamic> items = _extractList(responseBody);

    final Map<int, NoteEntity> notesById = <int, NoteEntity>{};

    for (final dynamic item in items) {
      if (item is! Map) {
        throw StateError('The notes API returned an invalid note record.');
      }

      final NoteEntity note = _noteFromJson(_convertMap(item));

      if (note.id <= 0) {
        throw StateError('The notes API returned a note without a valid ID.');
      }

      notesById[note.id] = note;
    }

    return notesById.values.toList(growable: false);
  }

  // ===========================================================================
  // GET NOTE DETAIL
  // GET /api/note/{id}
  // ===========================================================================

  @override
  Future<NoteEntity> getNoteDetail(int noteId) async {
    if (noteId <= 0) {
      throw ArgumentError.value(
        noteId,
        'noteId',
        'Note ID must be greater than zero.',
      );
    }

    final dynamic response = await apiClient.get(
      ApiEndpoints.noteDetail(noteId),
    );

    final dynamic responseBody = _decodedResponseBody(response);

    ApiParser.ensureSuccess(
      responseBody,
      fallbackMessage: 'Unable to load the requested note.',
    );

    final Map<String, dynamic> noteJson = _extractObject(responseBody);

    final NoteEntity note = _noteFromJson(noteJson);

    if (note.id <= 0) {
      throw StateError(
        'The note detail response does not contain a valid note ID.',
      );
    }

    if (note.id != noteId) {
      throw StateError(
        'The API returned note ${note.id} instead of the requested note '
        '$noteId.',
      );
    }

    return note;
  }

  // ===========================================================================
  // SAVE NOTE HEADER
  // POST /api/note/save
  // ===========================================================================

  @override
  Future<int> saveNote({
    required int noteId,
    required int folderId,
    required String title,
  }) async {
    if (noteId < 0) {
      throw ArgumentError.value(
        noteId,
        'noteId',
        'Note ID cannot be negative.',
      );
    }

    if (folderId <= 0) {
      throw ArgumentError.value(
        folderId,
        'folderId',
        'Folder ID must be greater than zero.',
      );
    }

    final String cleanTitle = title.trim();

    if (cleanTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', 'Note title is required.');
    }

    /*
     * The create endpoint can return data: null. Capture matching IDs before
     * creating so the fallback lookup cannot select an older note that has
     * the same folder and title.
     */
    final Set<int> existingMatchingIds = noteId == 0
        ? await _findMatchingNoteIds(folderId: folderId, title: cleanTitle)
        : <int>{};

    final dynamic response = await apiClient.post(
      ApiEndpoints.saveNote,
      body: <String, dynamic>{
        'noteId': noteId,
        'folderId': folderId,
        'title': cleanTitle,
      },
    );

    final dynamic responseBody = _decodedResponseBody(response);

    ApiParser.ensureSuccess(
      responseBody,
      fallbackMessage: 'Unable to save the note.',
    );

    int savedNoteId = _extractSavedNoteId(responseBody);

    if (savedNoteId <= 0 && noteId == 0) {
      debugPrint(
        'SAVE NOTE: The API omitted NoteId; resolving it from the note list.',
      );
    }

    /*
     * Some APIs return only a success message when an
     * existing note is updated. In that case, keep the
     * ID that was passed into this method.
     */
    if (savedNoteId <= 0 && noteId > 0) {
      savedNoteId = noteId;
    }

    if (noteId > 0 && savedNoteId > 0 && savedNoteId != noteId) {
      throw StateError(
        'The API returned note $savedNoteId while updating note $noteId.',
      );
    }

    /*
     * Some create APIs save the record but return only:
     *
     * {
     *   "code": 200,
     *   "message": "Success"
     * }
     *
     * When this happens, reload the note list and find
     * the newly created note using folder and title.
     */
    if (savedNoteId <= 0 && noteId == 0) {
      savedNoteId = await _findCreatedNoteId(
        folderId: folderId,
        title: cleanTitle,
        excludedIds: existingMatchingIds,
      );
    }

    if (savedNoteId <= 0) {
      throw StateError(
        'The API saved the request but did not return '
        'a usable note ID.\n\n'
        'Response: ${_responsePreview(responseBody)}',
      );
    }

    return savedNoteId;
  }

  // ===========================================================================
  // SAVE NOTE CONTENT
  // POST /api/note/save-content with {id, title, content}
  // ===========================================================================

  @override
  Future<void> saveContent({
    required int id,
    required String title,
    required List<Map<String, dynamic>> content,
  }) async {
    if (id <= 0) {
      throw ArgumentError.value(id, 'id', 'Note ID must be greater than zero.');
    }

    final String cleanTitle = title.trim();

    if (cleanTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', 'Note title is required.');
    }

    final List<Map<String, dynamic>> contentSnapshot = content
        .map((Map<String, dynamic> block) {
          return _deepCopyMap(block);
        })
        .toList(growable: false);

    /*
     * Send content as an actual JSON array.
     *
     * Correct:
     *   "content": [...]
     *
     * Incorrect:
     *   "content": "[...]"
     */
    final Map<String, dynamic> body = <String, dynamic>{
      'id': id,
      'title': cleanTitle,
      'content': contentSnapshot,
    };

    // A 404 means the target note no longer exists. Do not retry against the
    // header endpoint because that could recreate a deleted record.
    final dynamic response = await apiClient.post(
      ApiEndpoints.saveContent,
      body: body,
    );

    ApiParser.ensureSuccess(
      _decodedResponseBody(response),
      fallbackMessage: 'Unable to save the note content.',
    );
  }

  // ===========================================================================
  // UPLOAD NOTE ATTACHMENT
  // POST /api/note/attachment
  // ===========================================================================

  @override
  Future<void> uploadAttachment({
    required int noteId,
    required String filePath,
    required String blockId,
    required int displayOrder,
  }) async {
    if (noteId <= 0) {
      throw ArgumentError.value(
        noteId,
        'noteId',
        'Note ID must be greater than zero.',
      );
    }

    final String cleanFilePath = filePath.trim();

    if (cleanFilePath.isEmpty) {
      throw ArgumentError.value(
        filePath,
        'filePath',
        'Attachment file path is required.',
      );
    }

    final String cleanBlockId = blockId.trim();

    if (cleanBlockId.isEmpty) {
      throw ArgumentError.value(blockId, 'blockId', 'Block ID is required.');
    }

    if (displayOrder <= 0) {
      throw ArgumentError.value(
        displayOrder,
        'displayOrder',
        'Display order must be greater than zero.',
      );
    }

    final dynamic response = await apiClient.uploadFile(
      ApiEndpoints.noteAttachment,
      filePath: cleanFilePath,
      fileName: _fileNameFromPath(cleanFilePath),
      fields: <String, dynamic>{
        'Id': noteId.toString(),
        'BlockId': cleanBlockId,
        'DisplayOrder': displayOrder.toString(),
      },
    );

    ApiParser.ensureSuccess(
      _decodedResponseBody(response),
      fallbackMessage: 'Unable to upload the attachment.',
    );
  }

  // ===========================================================================
  // UPDATE NOTE STATE
  // POST /api/note/update-state
  // ===========================================================================

  @override
  Future<void> updateState({
    required int noteId,
    required bool isPinned,
    required bool isArchived,
    required bool isLocked,
    NoteStateField? changedField,
  }) async {
    if (noteId <= 0) {
      throw ArgumentError.value(
        noteId,
        'noteId',
        'Note ID must be greater than zero.',
      );
    }

    final List<NoteStateField> fieldsToUpdate;

    if (changedField != null) {
      fieldsToUpdate = <NoteStateField>[changedField];
    } else {
      final NoteEntity current = await getNoteDetail(noteId);

      fieldsToUpdate = <NoteStateField>[
        if (current.isPinned != isPinned) NoteStateField.pinned,
        if (current.isArchived != isArchived) NoteStateField.archived,
        if (current.isLocked != isLocked) NoteStateField.locked,
      ];
    }

    for (final NoteStateField field in fieldsToUpdate) {
      final bool value = switch (field) {
        NoteStateField.pinned => isPinned,
        NoteStateField.archived => isArchived,
        NoteStateField.locked => isLocked,
      };

      await _updateSingleState(
        noteId: noteId,
        field: field,
        value: value,
        isPinned: isPinned,
        isArchived: isArchived,
        isLocked: isLocked,
      );
    }
  }

  Future<void> _updateSingleState({
    required int noteId,
    required NoteStateField field,
    required bool value,
    bool? isPinned,
    bool? isArchived,
    bool? isLocked,
  }) async {
    final String state = switch (field) {
      NoteStateField.pinned => 'pinned',
      NoteStateField.archived => 'archived',
      NoteStateField.locked => 'locked',
    };
    final String action = switch (field) {
      NoteStateField.pinned => value ? 'pin' : 'unpin',
      NoteStateField.archived => value ? 'archive' : 'unarchive',
      NoteStateField.locked => value ? 'lock' : 'unlock',
    };

    final dynamic response = await apiClient.post(
      ApiEndpoints.updateNoteState,
      body: <String, dynamic>{
        'id': noteId,
        'noteId': noteId,
        'note_id': noteId,
        'state': state,
        'stateName': state,
        'state_name': state,
        'field': switch (field) {
          NoteStateField.pinned => 'isPinned',
          NoteStateField.archived => 'isArchived',
          NoteStateField.locked => 'isLocked',
        },
        'action': action,
        'value': value,
        if (isPinned != null) ...<String, dynamic>{
          'isPinned': isPinned,
          'is_pinned': isPinned,
          'pinned': isPinned,
        },
        if (isArchived != null) ...<String, dynamic>{
          'isArchived': isArchived,
          'is_archived': isArchived,
          'archived': isArchived,
        },
        if (isLocked != null) ...<String, dynamic>{
          'isLocked': isLocked,
          'is_locked': isLocked,
          'locked': isLocked,
        },
      },
    );

    ApiParser.ensureSuccess(
      _decodedResponseBody(response),
      fallbackMessage: 'Unable to update the note state.',
    );
  }

  // ===========================================================================
  // FIND NEWLY CREATED NOTE
  // ===========================================================================

  Future<int> _findCreatedNoteId({
    required int folderId,
    required String title,
    required Set<int> excludedIds,
  }) async {
    const List<Duration> retryDelays = <Duration>[
      Duration.zero,
      Duration(milliseconds: 200),
      Duration(milliseconds: 400),
      Duration(milliseconds: 800),
      Duration(milliseconds: 1200),
    ];

    Object? lastError;

    for (final Duration delay in retryDelays) {
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }

      try {
        final Set<int> matchingIds = await _findMatchingNoteIds(
          folderId: folderId,
          title: title,
          rethrowErrors: true,
        );

        final List<int> newIds = matchingIds.where((int id) {
          return !excludedIds.contains(id);
        }).toList()..sort();

        if (newIds.isNotEmpty) {
          return newIds.last;
        }
      } catch (error) {
        lastError = error;
      }
    }

    if (lastError != null) {
      debugPrint('FIND CREATED NOTE ERROR: $lastError');
    }

    return 0;
  }

  Future<Set<int>> _findMatchingNoteIds({
    required int folderId,
    required String title,
    bool rethrowErrors = false,
  }) async {
    try {
      final List<NoteEntity> noteList = await getNotes();

      final String normalizedTitle = title.trim().toLowerCase();

      return noteList
          .where((NoteEntity note) {
            return note.id > 0 &&
                note.folderId == folderId &&
                note.title.trim().toLowerCase() == normalizedTitle;
          })
          .map((NoteEntity note) => note.id)
          .toSet();
    } catch (_) {
      if (rethrowErrors) {
        rethrow;
      }

      return <int>{};
    }
  }

  // ===========================================================================
  // RESPONSE BODY
  // ===========================================================================

  dynamic _decodedResponseBody(dynamic response) {
    if (response == null) {
      return null;
    }

    /*
     * ApiClient may already return response.data.
     */
    if (response is Map ||
        response is List ||
        response is String ||
        response is num ||
        response is bool) {
      return _decodeJsonString(response);
    }

    /*
     * Support Dio Response when ApiClient returns
     * the complete Response object.
     */
    try {
      final dynamic data = (response as dynamic).data;

      return _decodeJsonString(data);
    } catch (_) {
      // Use the original response.
    }

    return _decodeJsonString(response);
  }

  // ===========================================================================
  // EXTRACT NOTE LIST
  // ===========================================================================

  List<dynamic> _extractList(dynamic response) {
    if (response == null) {
      return <dynamic>[];
    }

    final ({bool found, List<dynamic> items}) result = _tryExtractList(
      response,
    );

    if (!result.found) {
      throw StateError('The note list response has an invalid format.');
    }

    return result.items;
  }

  ({bool found, List<dynamic> items}) _tryExtractList(
    dynamic value, {
    int depth = 0,
  }) {
    if (depth > 12) {
      return (found: false, items: <dynamic>[]);
    }

    final dynamic decoded = _decodeJsonValue(value);

    if (decoded is List) {
      return (found: true, items: decoded);
    }

    if (decoded is! Map) {
      return (found: false, items: <dynamic>[]);
    }

    final Map<String, dynamic> map = _convertMap(decoded);
    final List<dynamic>? collections = _extractNoteCollections(map);

    if (collections != null) {
      return (found: true, items: collections);
    }

    if (_looksLikeNote(map)) {
      return (found: true, items: <dynamic>[map]);
    }

    for (final String key in <String>[
      'data',
      'result',
      'items',
      'notes',
      'note',
      'list',
      'rows',
      'records',
      'payload',
      'value',
    ]) {
      if (!_containsKeyIgnoreCase(map, key)) {
        continue;
      }

      final dynamic nested = _getValueIgnoreCase(map, key);

      if (nested == null) {
        return (found: true, items: <dynamic>[]);
      }

      final ({bool found, List<dynamic> items}) result = _tryExtractList(
        nested,
        depth: depth + 1,
      );

      if (result.found) {
        return result;
      }
    }

    return (found: false, items: <dynamic>[]);
  }

  List<dynamic>? _extractNoteCollections(Map<String, dynamic> map) {
    final dynamic activeNotes = _decodeJsonValue(
      _firstValueIgnoreCase(map, <String>['note', 'notes']),
    );
    final dynamic archivedNotes = _decodeJsonValue(
      _firstValueIgnoreCase(map, <String>[
        'archive',
        'archived',
        'archivedNotes',
      ]),
    );
    final dynamic trashedNotes = _decodeJsonValue(
      _firstValueIgnoreCase(map, <String>[
        'trash',
        'trashed',
        'deleted',
        'deletedNotes',
      ]),
    );

    if (activeNotes is! List &&
        archivedNotes is! List &&
        trashedNotes is! List) {
      return null;
    }

    return <dynamic>[
      if (activeNotes is List) ...activeNotes,
      if (archivedNotes is List)
        ...archivedNotes.map(
          (dynamic item) => _markNoteCollectionItem(item, isArchived: true),
        ),
      if (trashedNotes is List)
        ...trashedNotes.map(
          (dynamic item) => _markNoteCollectionItem(item, isInTrash: true),
        ),
    ];
  }

  dynamic _markNoteCollectionItem(
    dynamic item, {
    bool isArchived = false,
    bool isInTrash = false,
  }) {
    if (item is! Map) {
      return item;
    }

    final Map<String, dynamic> result = _convertMap(item);

    if (isArchived) {
      _setValueIgnoreCase(result, 'isArchived', true);
    }

    if (isInTrash) {
      _setValueIgnoreCase(result, 'isInTrash', true);
    }

    return result;
  }

  // ===========================================================================
  // EXTRACT NOTE DETAIL OBJECT
  // ===========================================================================

  Map<String, dynamic> _extractObject(dynamic response) {
    if (response == null) {
      throw StateError('The note detail response is empty.');
    }

    final Map<String, dynamic>? note = _tryExtractObject(response);

    if (note == null) {
      final dynamic decoded = _decodeJsonValue(response);

      if (decoded is List && decoded.isEmpty) {
        throw StateError('The requested note was not found.');
      }

      if (decoded is Map && _hasExplicitEmptyNoteValue(_convertMap(decoded))) {
        throw StateError('The requested note was not found.');
      }

      throw StateError('The note detail response has an invalid format.');
    }

    return note;
  }

  Map<String, dynamic>? _tryExtractObject(dynamic value, {int depth = 0}) {
    if (depth > 12) {
      return null;
    }

    final dynamic decoded = _decodeJsonValue(value);

    if (decoded is List) {
      for (final dynamic item in decoded) {
        final Map<String, dynamic>? result = _tryExtractObject(
          item,
          depth: depth + 1,
        );

        if (result != null) {
          return result;
        }
      }

      return null;
    }

    if (decoded is! Map) {
      return null;
    }

    final Map<String, dynamic> map = _convertMap(decoded);

    if (_looksLikeNote(map)) {
      return map;
    }

    for (final String key in <String>[
      'data',
      'result',
      'note',
      'notes',
      'item',
      'items',
      'record',
      'records',
      'row',
      'rows',
      'payload',
      'value',
    ]) {
      if (!_containsKeyIgnoreCase(map, key)) {
        continue;
      }

      final Map<String, dynamic>? result = _tryExtractObject(
        _getValueIgnoreCase(map, key),
        depth: depth + 1,
      );

      if (result != null) {
        return result;
      }
    }

    return null;
  }

  bool _hasExplicitEmptyNoteValue(Map<String, dynamic> map) {
    for (final String key in <String>[
      'data',
      'result',
      'note',
      'notes',
      'item',
      'items',
      'record',
      'records',
      'row',
      'rows',
    ]) {
      if (!_containsKeyIgnoreCase(map, key)) {
        continue;
      }

      final dynamic nested = _decodeJsonValue(_getValueIgnoreCase(map, key));

      if (nested == null || (nested is List && nested.isEmpty)) {
        return true;
      }

      if (nested is Map && _hasExplicitEmptyNoteValue(_convertMap(nested))) {
        return true;
      }
    }

    return false;
  }

  // ===========================================================================
  // EXTRACT SAVED NOTE ID
  // ===========================================================================

  int _extractSavedNoteId(dynamic value, {int depth = 0}) {
    if (value == null || depth > 12) {
      return 0;
    }

    if (value is int) {
      return value > 0 ? value : 0;
    }

    if (value is num) {
      final int result = value.toInt();

      return result > 0 ? result : 0;
    }

    if (value is String) {
      final String text = value.trim();

      if (text.isEmpty) {
        return 0;
      }

      final int directId = _positiveInt(text);

      if (directId > 0) {
        return directId;
      }

      /*
       * Handles JSON returned as a string:
       *
       * "{\"data\":{\"id\":25}}"
       */
      try {
        final dynamic decoded = jsonDecode(text);

        final int decodedId = _extractSavedNoteId(decoded, depth: depth + 1);

        if (decodedId > 0) {
          return decodedId;
        }
      } catch (_) {
        // The response is not a JSON string.
      }

      /*
       * Handles text responses:
       *
       * NoteId: 25
       * Id = 25
       * CreatedId: 25
       */
      final RegExp idPattern = RegExp(
        r'(?:"?(?:note[_\s-]?id|new[_\s-]?id|saved[_\s-]?id|'
        r'inserted[_\s-]?id|created[_\s-]?id|record[_\s-]?id|id)"?)'
        r'\s*[:=]\s*"?(\d+)"?',
        caseSensitive: false,
      );

      final RegExpMatch? match = idPattern.firstMatch(text);

      if (match != null) {
        return _positiveInt(match.group(1));
      }

      return 0;
    }

    if (value is List) {
      for (final dynamic item in value) {
        final int foundId = _extractSavedNoteId(item, depth: depth + 1);

        if (foundId > 0) {
          return foundId;
        }
      }

      return 0;
    }

    if (value is! Map) {
      return 0;
    }

    final Map<String, dynamic> map = _convertMap(value);

    /*
     * Search explicit ID properties first.
     */
    for (final MapEntry<String, dynamic> entry in map.entries) {
      final String normalizedKey = _normalizeKey(entry.key);

      final bool isIdField =
          normalizedKey == 'id' ||
          normalizedKey == 'noteid' ||
          normalizedKey == 'newid' ||
          normalizedKey == 'newnoteid' ||
          normalizedKey == 'savedid' ||
          normalizedKey == 'savednoteid' ||
          normalizedKey == 'insertid' ||
          normalizedKey == 'insertedid' ||
          normalizedKey == 'insertednoteid' ||
          normalizedKey == 'createdid' ||
          normalizedKey == 'creatednoteid' ||
          normalizedKey == 'recordid' ||
          normalizedKey == 'resultid' ||
          normalizedKey == 'returnid' ||
          normalizedKey == 'outputid';

      if (!isIdField) {
        continue;
      }

      final int foundId = _positiveInt(entry.value);

      if (foundId > 0) {
        return foundId;
      }

      final int nestedId = _extractSavedNoteId(entry.value, depth: depth + 1);

      if (nestedId > 0) {
        return nestedId;
      }
    }

    /*
     * Search common response wrappers.
     */
    const List<String> wrapperKeys = <String>[
      'data',
      'result',
      'note',
      'item',
      'payload',
      'value',
      'record',
      'object',
      'response',
      'returnvalue',
    ];

    for (final String wrapperKey in wrapperKeys) {
      dynamic nestedValue;

      for (final MapEntry<String, dynamic> entry in map.entries) {
        if (_normalizeKey(entry.key) == wrapperKey) {
          nestedValue = entry.value;
          break;
        }
      }

      if (nestedValue == null) {
        continue;
      }

      final int foundId = _extractSavedNoteId(nestedValue, depth: depth + 1);

      if (foundId > 0) {
        return foundId;
      }
    }

    /*
     * Search any remaining nested maps and lists.
     * Plain numbers under fields such as statusCode
     * are ignored.
     */
    for (final dynamic nestedValue in map.values) {
      if (nestedValue is! Map && nestedValue is! List) {
        continue;
      }

      final int foundId = _extractSavedNoteId(nestedValue, depth: depth + 1);

      if (foundId > 0) {
        return foundId;
      }
    }

    return 0;
  }

  // ===========================================================================
  // NOTE MAPPER
  // ===========================================================================

  NoteEntity _noteFromJson(Map<String, dynamic> json) {
    final dynamic rawFolder = _firstValueIgnoreCase(json, <String>['folder']);
    final Map<String, dynamic>? folder = rawFolder is Map
        ? _convertMap(rawFolder)
        : null;
    final List<Map<String, dynamic>> content = _parseNoteContent(json);
    final int responseAttachmentCount = _toInt(
      _firstValueIgnoreCase(json, <String>[
        'attachmentCount',
        'attachmentsCount',
        'fileCount',
      ]),
    );
    final int parsedAttachmentCount = content.where((
      Map<String, dynamic> block,
    ) {
      return _normalizedBlockType(block) == 'attachment';
    }).length;

    return NoteEntity(
      id: _toInt(_firstValueIgnoreCase(json, <String>['id', 'noteId'])),
      folderId: _toInt(
        _firstValueIgnoreCase(json, <String>['folderId']) ??
            (folder == null
                ? null
                : _firstValueIgnoreCase(folder, <String>['id', 'folderId'])),
      ),
      folderName:
          (_firstValueIgnoreCase(json, <String>['folderName']) ??
                  (folder == null
                      ? null
                      : _firstValueIgnoreCase(folder, <String>[
                          'name',
                          'folderName',
                        ])))
              ?.toString()
              .trim() ??
          '',
      title:
          _firstValueIgnoreCase(json, <String>[
            'title',
            'noteTitle',
            'name',
          ])?.toString() ??
          '',
      content: content,
      isPinned: _toBool(
        _firstValueIgnoreCase(json, <String>['isPinned', 'pinned']),
      ),
      isArchived: _toBool(
        _firstValueIgnoreCase(json, <String>['isArchived', 'archived']),
      ),
      isLocked: _toBool(
        _firstValueIgnoreCase(json, <String>['isLocked', 'locked']),
      ),
      isInTrash: _toBool(
        _firstValueIgnoreCase(json, <String>[
          'isInTrash',
          'isDeleted',
          'deleted',
        ]),
      ),
      sortOrder: _toInt(_firstValueIgnoreCase(json, <String>['sortOrder'])),
      attachmentCount: responseAttachmentCount > 0
          ? responseAttachmentCount
          : parsedAttachmentCount,
      pinnedAt: _toDateTime(_firstValueIgnoreCase(json, <String>['pinnedAt'])),
      createdAt: _toDateTime(
        _firstValueIgnoreCase(json, <String>['createdAt']),
      ),
      updatedAt: _toDateTime(
        _firstValueIgnoreCase(json, <String>['updatedAt']),
      ),
      deletedAt: _toDateTime(
        _firstValueIgnoreCase(json, <String>['deletedAt']),
      ),
    );
  }

  // ===========================================================================
  // CONTENT PARSER
  // ===========================================================================

  List<Map<String, dynamic>> _parseNoteContent(Map<String, dynamic> json) {
    final List<Map<String, dynamic>> result = _parseContent(
      _firstValueIgnoreCase(json, <String>[
        'content',
        'contentJson',
        'blocks',
        'noteContent',
        'body',
      ]),
    );

    if (!result.any((Map<String, dynamic> block) {
      return _normalizedBlockType(block) == 'text';
    })) {
      final String preview =
          _firstValueIgnoreCase(json, <String>[
            'previewText',
            'plainText',
            'text',
          ])?.toString().trim() ??
          '';

      if (preview.isNotEmpty) {
        result.insert(0, <String, dynamic>{
          'id': 'preview-text',
          'blockId': 'preview-text',
          'type': 'text',
          'text': preview,
          'displayOrder': 1,
        });
      }
    }

    final List<Map<String, dynamic>> attachments = _parseAttachments(
      _firstValueIgnoreCase(json, <String>[
        'attachments',
        'attachment',
        'files',
        'images',
      ]),
    );

    for (final Map<String, dynamic> attachment in attachments) {
      final String identity = _blockIdentity(attachment);
      final int existingIndex = identity.isEmpty
          ? -1
          : result.indexWhere((Map<String, dynamic> block) {
              return _blockIdentity(block) == identity;
            });

      if (existingIndex >= 0) {
        result[existingIndex] = <String, dynamic>{
          ...result[existingIndex],
          ...attachment,
          'type': 'attachment',
        };
      } else {
        result.add(attachment);
      }
    }

    result.sort((Map<String, dynamic> first, Map<String, dynamic> second) {
      final int firstOrder = _toInt(first['displayOrder']);
      final int secondOrder = _toInt(second['displayOrder']);

      if (firstOrder <= 0 && secondOrder <= 0) {
        return 0;
      }

      if (firstOrder <= 0) {
        return 1;
      }

      if (secondOrder <= 0) {
        return -1;
      }

      return firstOrder.compareTo(secondOrder);
    });

    for (int index = 0; index < result.length; index++) {
      result[index].putIfAbsent('displayOrder', () => index + 1);
    }

    return result;
  }

  List<Map<String, dynamic>> _parseContent(dynamic value) {
    if (value == null) {
      return <Map<String, dynamic>>[];
    }

    final dynamic parsedValue = _decodeJsonValue(value);

    if (parsedValue is String) {
      final String cleanValue = parsedValue.trim();

      if (cleanValue.isEmpty) {
        return <Map<String, dynamic>>[];
      }

      return <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'legacy-text',
          'blockId': 'legacy-text',
          'type': 'text',
          'text': cleanValue,
          'displayOrder': 1,
        },
      ];
    }

    if (parsedValue is Map) {
      final Map<String, dynamic> map = _convertMap(parsedValue);

      if (!_looksLikeContentBlock(map)) {
        for (final String key in <String>[
          'blocks',
          'content',
          'items',
          'data',
        ]) {
          if (!_containsKeyIgnoreCase(map, key)) {
            continue;
          }

          final dynamic nested = _getValueIgnoreCase(map, key);

          if (nested is List || nested is String || nested is Map) {
            return _parseContent(nested);
          }
        }
      }

      return <Map<String, dynamic>>[_canonicalContentBlock(map)];
    }

    if (parsedValue is! List) {
      return <Map<String, dynamic>>[];
    }

    return parsedValue
        .whereType<Map>()
        .map((Map<dynamic, dynamic> block) {
          return _canonicalContentBlock(_convertMap(block));
        })
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _parseAttachments(dynamic value) {
    if (value == null) {
      return <Map<String, dynamic>>[];
    }

    final dynamic decoded = _decodeJsonValue(value);
    final List<dynamic> values;

    if (decoded is List) {
      values = decoded;
    } else if (decoded is Map) {
      final Map<String, dynamic> map = _convertMap(decoded);
      final dynamic nested = _firstValueIgnoreCase(map, <String>[
        'items',
        'attachments',
        'files',
        'data',
      ]);

      if (nested != null && !identical(nested, decoded)) {
        return _parseAttachments(nested);
      }

      values = <dynamic>[map];
    } else if (decoded is String && decoded.trim().isNotEmpty) {
      values = <dynamic>[decoded.trim()];
    } else {
      return <Map<String, dynamic>>[];
    }

    final List<Map<String, dynamic>> result = <Map<String, dynamic>>[];

    for (int index = 0; index < values.length; index++) {
      final dynamic item = values[index];

      if (item is String && item.trim().isNotEmpty) {
        final String path = item.trim();

        result.add(<String, dynamic>{
          'id': path,
          'blockId': path,
          'type': 'attachment',
          'url': path,
          'displayName': _fileNameFromPath(path),
          'displayOrder': index + 1,
        });
        continue;
      }

      if (item is Map) {
        final Map<String, dynamic> block = _canonicalContentBlock(
          _convertMap(item),
          forcedType: 'attachment',
        );
        block.putIfAbsent('displayOrder', () => index + 1);
        result.add(block);
      }
    }

    return result;
  }

  Map<String, dynamic> _canonicalContentBlock(
    Map<String, dynamic> source, {
    String? forcedType,
  }) {
    final Map<String, dynamic> block = _deepCopyMap(source);
    final dynamic rawItems = _firstValueIgnoreCase(block, <String>[
      'items',
      'checklistItems',
      'tasks',
    ]);
    final String rawType =
        _firstValueIgnoreCase(block, <String>[
          'type',
          'blockType',
          'contentType',
        ])?.toString().trim().toLowerCase() ??
        '';
    final String inferredType =
        forcedType ??
        (rawType.isNotEmpty
            ? _canonicalBlockType(rawType)
            : rawItems is List
            ? 'checklist'
            : _firstValueIgnoreCase(block, <String>[
                    'attachmentId',
                    'fileName',
                    'filePath',
                    'url',
                  ]) !=
                  null
            ? 'attachment'
            : 'text');
    final dynamic id = _firstValueIgnoreCase(block, <String>[
      'id',
      'blockId',
      'attachmentId',
    ]);
    final dynamic blockId = _firstValueIgnoreCase(block, <String>[
      'blockId',
      'id',
    ]);

    if (id != null) {
      block['id'] = id.toString();
    }

    if (blockId != null) {
      block['blockId'] = blockId.toString();
    } else if (id != null) {
      block['blockId'] = id.toString();
    }

    block['type'] = inferredType;

    final int displayOrder = _toInt(
      _firstValueIgnoreCase(block, <String>[
        'displayOrder',
        'order',
        'sortOrder',
      ]),
    );

    if (displayOrder > 0) {
      block['displayOrder'] = displayOrder;
    }

    if (inferredType == 'text') {
      final dynamic text = _firstValueIgnoreCase(block, <String>[
        'text',
        'body',
        'value',
        'content',
      ]);

      block['text'] = text?.toString() ?? '';
    }

    if (inferredType == 'checklist') {
      final List<Map<String, dynamic>> items = <Map<String, dynamic>>[];

      if (rawItems is List) {
        for (final dynamic rawItem in rawItems) {
          if (rawItem is! Map) {
            continue;
          }

          final Map<String, dynamic> item = _deepCopyMap(_convertMap(rawItem));
          final dynamic itemId = _firstValueIgnoreCase(item, <String>[
            'id',
            'itemId',
            'taskId',
          ]);

          if (itemId != null) {
            item['id'] = itemId.toString();
          }

          item['text'] =
              _firstValueIgnoreCase(item, <String>[
                'text',
                'title',
                'label',
                'value',
              ])?.toString() ??
              '';
          item['checked'] = _toBool(
            _firstValueIgnoreCase(item, <String>[
              'checked',
              'isChecked',
              'completed',
              'isCompleted',
            ]),
          );
          items.add(item);
        }
      }

      block['items'] = items;
    }

    if (inferredType == 'attachment') {
      for (final ({String canonical, List<String> aliases}) field
          in <({String canonical, List<String> aliases})>[
            (
              canonical: 'attachmentId',
              aliases: <String>['attachmentId', 'fileId'],
            ),
            (
              canonical: 'displayName',
              aliases: <String>['displayName', 'fileName', 'name'],
            ),
            (
              canonical: 'fileName',
              aliases: <String>['fileName', 'displayName'],
            ),
            (
              canonical: 'url',
              aliases: <String>['url', 'fileUrl', 'downloadUrl'],
            ),
            (canonical: 'filePath', aliases: <String>['filePath', 'path']),
            (
              canonical: 'attachmentType',
              aliases: <String>['attachmentType', 'fileType', 'mimeType'],
            ),
          ]) {
        final dynamic fieldValue = _firstValueIgnoreCase(block, field.aliases);

        if (fieldValue != null) {
          block[field.canonical] = fieldValue;
        }
      }
    }

    return block;
  }

  String _normalizedBlockType(Map<String, dynamic> block) {
    final String value =
        _firstValueIgnoreCase(block, <String>[
          'type',
          'blockType',
          'contentType',
        ])?.toString().trim().toLowerCase() ??
        '';

    return _canonicalBlockType(value);
  }

  String _canonicalBlockType(String value) {
    switch (_normalizeKey(value)) {
      case 'text':
      case 'paragraph':
      case 'body':
      case 'statement':
        return 'text';
      case 'checklist':
      case 'todo':
      case 'tasklist':
      case 'tasks':
        return 'checklist';
      case 'attachment':
      case 'file':
      case 'document':
      case 'image':
      case 'photo':
        return 'attachment';
      default:
        return value.trim().toLowerCase();
    }
  }

  bool _looksLikeContentBlock(Map<String, dynamic> map) {
    if (<String>['type', 'blockType', 'contentType'].any((String key) {
      return _containsKeyIgnoreCase(map, key);
    })) {
      return true;
    }

    final bool hasId = <String>['id', 'blockId', 'attachmentId'].any((
      String key,
    ) {
      return _containsKeyIgnoreCase(map, key);
    });
    final bool hasContent =
        <String>[
          'text',
          'items',
          'checklistItems',
          'fileName',
          'filePath',
          'url',
        ].any((String key) {
          return _containsKeyIgnoreCase(map, key);
        });

    return hasId && hasContent;
  }

  String _blockIdentity(Map<String, dynamic> block) {
    final dynamic value = _firstValueIgnoreCase(block, <String>[
      'blockId',
      'id',
      'attachmentId',
      'url',
      'filePath',
    ]);

    return value?.toString().trim() ?? '';
  }

  // ===========================================================================
  // GENERAL HELPERS
  // ===========================================================================

  dynamic _decodeJsonString(dynamic value) {
    if (value is! String) {
      return value;
    }

    final String text = value.trim();

    if (text.isEmpty) {
      return value;
    }

    try {
      return jsonDecode(text);
    } catch (_) {
      return value;
    }
  }

  dynamic _decodeJsonValue(dynamic value) {
    dynamic current = value;

    for (int depth = 0; depth < 5 && current is String; depth++) {
      final dynamic decoded = _decodeJsonString(current);

      if (decoded is String && decoded == current) {
        break;
      }

      current = decoded;
    }

    return current;
  }

  Map<String, dynamic> _convertMap(Map<dynamic, dynamic> map) {
    return map.map((dynamic key, dynamic value) {
      return MapEntry<String, dynamic>(key.toString(), value);
    });
  }

  Map<String, dynamic> _deepCopyMap(Map<String, dynamic> source) {
    return source.map((String key, dynamic value) {
      return MapEntry<String, dynamic>(key, _deepCopyValue(value));
    });
  }

  dynamic _deepCopyValue(dynamic value) {
    if (value is Map) {
      return _deepCopyMap(_convertMap(value));
    }

    if (value is List) {
      return value.map<dynamic>(_deepCopyValue).toList(growable: false);
    }

    return value;
  }

  dynamic _getValueIgnoreCase(Map<String, dynamic> map, String wantedKey) {
    final String normalizedWantedKey = _normalizeKey(wantedKey);
    dynamic result;

    for (final MapEntry<String, dynamic> entry in map.entries) {
      if (_normalizeKey(entry.key) == normalizedWantedKey) {
        result = entry.value;
      }
    }

    return result;
  }

  bool _containsKeyIgnoreCase(Map<String, dynamic> map, String wantedKey) {
    final String normalizedWantedKey = _normalizeKey(wantedKey);

    return map.keys.any((String key) {
      return _normalizeKey(key) == normalizedWantedKey;
    });
  }

  void _setValueIgnoreCase(
    Map<String, dynamic> map,
    String canonicalKey,
    dynamic value,
  ) {
    final String normalizedKey = _normalizeKey(canonicalKey);

    map.removeWhere((String key, dynamic _) {
      return _normalizeKey(key) == normalizedKey;
    });
    map[canonicalKey] = value;
  }

  dynamic _firstValueIgnoreCase(Map<String, dynamic> map, List<String> keys) {
    for (final String key in keys) {
      final dynamic value = _getValueIgnoreCase(map, key);

      if (value != null) {
        return value;
      }
    }

    return null;
  }

  String _normalizeKey(String key) {
    return key.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  bool _looksLikeNote(Map<String, dynamic> map) {
    final bool hasId = <String>['id', 'noteId'].any((String key) {
      return _containsKeyIgnoreCase(map, key);
    });
    final bool hasNoteData =
        <String>[
          'title',
          'noteTitle',
          'content',
          'contentJson',
          'blocks',
          'folderId',
          'isPinned',
          'isArchived',
          'isLocked',
          'createdAt',
        ].any((String key) {
          return _containsKeyIgnoreCase(map, key);
        });

    return hasId && hasNoteData;
  }

  int _positiveInt(dynamic value) {
    final int parsed = _toInt(value);

    return parsed > 0 ? parsed : 0;
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString().trim() ?? '') ?? 0;
  }

  bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final String text = value?.toString().trim().toLowerCase() ?? '';

    return text == 'true' || text == '1' || text == 'yes' || text == 'y';
  }

  DateTime? _toDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    if (value is num) {
      final int numericValue = value.toInt();
      final int milliseconds = numericValue.abs() < 100000000000
          ? numericValue * 1000
          : numericValue;

      return DateTime.fromMillisecondsSinceEpoch(
        milliseconds,
        isUtc: true,
      ).toLocal();
    }

    final String text = value?.toString().trim() ?? '';

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }

    final num? numericValue = num.tryParse(text);

    if (numericValue != null) {
      return _toDateTime(numericValue);
    }

    return DateTime.tryParse(text);
  }

  String _fileNameFromPath(String filePath) {
    final String normalizedPath = filePath.replaceAll('\\', '/');

    final List<String> parts = normalizedPath.split('/');

    final String filename = parts.isNotEmpty ? parts.last.trim() : '';

    if (filename.isNotEmpty) {
      return filename;
    }

    return 'attachment';
  }

  String _responsePreview(dynamic response) {
    String text;

    try {
      text = jsonEncode(response);
    } catch (_) {
      text = response?.toString() ?? 'null';
    }

    const int maximumLength = 700;

    if (text.length <= maximumLength) {
      return text;
    }

    return '${text.substring(0, maximumLength)}...';
  }
}
