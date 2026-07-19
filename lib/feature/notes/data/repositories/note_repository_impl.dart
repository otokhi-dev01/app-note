import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/note_repository.dart';

class NoteRepositoryImpl implements NoteRepository {
  final ApiClient apiClient;

  const NoteRepositoryImpl({
    required this.apiClient,
  });

  // ===========================================================================
  // GET NOTE LIST
  // GET /api/note
  // ===========================================================================

  @override
  Future<List<NoteEntity>> getNotes() async {
    final dynamic response = await apiClient.get(
      ApiEndpoints.notes,
    );

    final dynamic responseBody =
    _extractResponseBody(response);

    final List<dynamic> items =
    _extractList(responseBody);

    return items
        .whereType<Map>()
        .map(
          (Map<dynamic, dynamic> item) {
        return _noteFromJson(
          _convertMap(item),
        );
      },
    )
        .where(
          (NoteEntity note) => note.id > 0,
    )
        .toList(
      growable: false,
    );
  }

  // ===========================================================================
  // GET NOTE DETAIL
  // GET /api/note/{id}
  // ===========================================================================

  @override
  Future<NoteEntity> getNoteDetail(
      int noteId,
      ) async {
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

    final dynamic responseBody =
    _extractResponseBody(response);

    final Map<String, dynamic> noteJson =
    _extractObject(responseBody);

    final NoteEntity note =
    _noteFromJson(noteJson);

    if (note.id <= 0) {
      throw StateError(
        'The note detail response does not contain a valid note ID.',
      );
    }

    return note;
  }

  // Compatibility method for older controller code.

  @override
  Future<NoteEntity> getNote(
      int noteId,
      ) {
    return getNoteDetail(noteId);
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
      throw ArgumentError.value(
        title,
        'title',
        'Note title is required.',
      );
    }

    final dynamic response = await apiClient.post(
      ApiEndpoints.saveNote,
      body: <String, dynamic>{
        'noteId': noteId,
        'folderId': folderId,
        'title': cleanTitle,
      },
    );

    final dynamic responseBody =
    _extractResponseBody(response);

    debugPrint(
      'SAVE NOTE RAW RESPONSE: $responseBody',
    );

    int savedNoteId =
    _extractSavedNoteId(responseBody);

    /*
     * Some APIs return only a success message when an
     * existing note is updated. In that case, keep the
     * ID that was passed into this method.
     */
    if (savedNoteId <= 0 && noteId > 0) {
      savedNoteId = noteId;
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
      savedNoteId =
      await _findCreatedNoteId(
        folderId: folderId,
        title: cleanTitle,
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
  // POST /api/note/save-content
  // ===========================================================================

  @override
  Future<void> saveContent({
    required int id,
    required String title,
    required List<Map<String, dynamic>> content,
  }) async {
    if (id <= 0) {
      throw ArgumentError.value(
        id,
        'id',
        'Note ID must be greater than zero.',
      );
    }

    final String cleanTitle = title.trim();

    if (cleanTitle.isEmpty) {
      throw ArgumentError.value(
        title,
        'title',
        'Note title is required.',
      );
    }

    final List<Map<String, dynamic>>
    contentSnapshot =
    content.map(
          (Map<String, dynamic> block) {
        return _deepCopyMap(block);
      },
    ).toList(
      growable: false,
    );

    /*
     * Send content as an actual JSON array.
     *
     * Correct:
     *   "content": [...]
     *
     * Incorrect:
     *   "content": "[...]"
     */
    await apiClient.post(
      ApiEndpoints.saveContent,
      body: <String, dynamic>{
        'id': id,
        'title': cleanTitle,
        'content': contentSnapshot,
      },
    );
  }

  // Compatibility method for older controller code.

  @override
  Future<void> saveNoteContent({
    required int id,
    required String title,
    required List<Map<String, dynamic>> content,
  }) {
    return saveContent(
      id: id,
      title: title,
      content: content,
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

    final String cleanFilePath =
    filePath.trim();

    if (cleanFilePath.isEmpty) {
      throw ArgumentError.value(
        filePath,
        'filePath',
        'Attachment file path is required.',
      );
    }

    final String cleanBlockId =
    blockId.trim();

    if (cleanBlockId.isEmpty) {
      throw ArgumentError.value(
        blockId,
        'blockId',
        'Block ID is required.',
      );
    }

    if (displayOrder <= 0) {
      throw ArgumentError.value(
        displayOrder,
        'displayOrder',
        'Display order must be greater than zero.',
      );
    }

    final MultipartFile attachment =
    await MultipartFile.fromFile(
      cleanFilePath,
      filename: _fileNameFromPath(
        cleanFilePath,
      ),
    );

    final FormData formData =
    FormData.fromMap(
      <String, dynamic>{
        /*
         * Keep these field names exactly as the API expects.
         */
        'Id': noteId.toString(),
        'File': attachment,
        'BlockId': cleanBlockId,
        'DisplayOrder':
        displayOrder.toString(),
      },
    );

    await apiClient.post(
      ApiEndpoints.noteAttachment,
      body: formData,
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
  }) async {
    if (noteId <= 0) {
      throw ArgumentError.value(
        noteId,
        'noteId',
        'Note ID must be greater than zero.',
      );
    }

    await apiClient.post(
      ApiEndpoints.updateNoteState,
      body: <String, dynamic>{
        'id': noteId,
        'isPinned': isPinned,
        'isArchived': isArchived,
        'isLocked': isLocked,
      },
    );
  }

  // ===========================================================================
  // FIND NEWLY CREATED NOTE
  // ===========================================================================

  Future<int> _findCreatedNoteId({
    required int folderId,
    required String title,
  }) async {
    try {
      /*
       * Give the backend a small amount of time to finish
       * committing the newly created note.
       */
      await Future<void>.delayed(
        const Duration(
          milliseconds: 250,
        ),
      );

      final List<NoteEntity> noteList =
      await getNotes();

      final String normalizedTitle =
      title.trim().toLowerCase();

      final List<NoteEntity>
      matchingNotes =
      noteList.where(
            (NoteEntity note) {
          return note.id > 0 &&
              note.folderId == folderId &&
              note.title
                  .trim()
                  .toLowerCase() ==
                  normalizedTitle;
        },
      ).toList();

      if (matchingNotes.isEmpty) {
        return 0;
      }

      /*
       * The newest record normally has the largest ID.
       */
      matchingNotes.sort(
            (
            NoteEntity first,
            NoteEntity second,
            ) {
          return second.id.compareTo(
            first.id,
          );
        },
      );

      return matchingNotes.first.id;
    } catch (error) {
      debugPrint(
        'FIND CREATED NOTE ERROR: $error',
      );

      return 0;
    }
  }

  // ===========================================================================
  // RESPONSE BODY
  // ===========================================================================

  dynamic _extractResponseBody(
      dynamic response,
      ) {
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
      return response;
    }

    /*
     * Support Dio Response when ApiClient returns
     * the complete Response object.
     */
    try {
      final dynamic data =
          (response as dynamic).data;

      if (data != null) {
        return data;
      }
    } catch (_) {
      // Use the original response.
    }

    return response;
  }

  // ===========================================================================
  // EXTRACT NOTE LIST
  // ===========================================================================

  List<dynamic> _extractList(
      dynamic response,
      ) {
    dynamic value = response;

    if (value == null) {
      return <dynamic>[];
    }

    value = _decodeJsonString(value);

    if (value is List) {
      return value;
    }

    if (value is! Map) {
      throw StateError(
        'The note list response has an invalid format.',
      );
    }

    final Map<String, dynamic> root =
    _convertMap(value);

    final dynamic data =
    _getValueIgnoreCase(
      root,
      'data',
    );

    if (data is List) {
      return data;
    }

    if (data is Map) {
      final Map<String, dynamic> dataMap =
      _convertMap(data);

      final dynamic nestedList =
      _firstValueIgnoreCase(
        dataMap,
        <String>[
          'items',
          'notes',
          'list',
          'rows',
          'records',
          'result',
        ],
      );

      if (nestedList is List) {
        return nestedList;
      }
    }

    final dynamic rootList =
    _firstValueIgnoreCase(
      root,
      <String>[
        'items',
        'notes',
        'list',
        'rows',
        'records',
        'result',
      ],
    );

    if (rootList is List) {
      return rootList;
    }

    return <dynamic>[];
  }

  // ===========================================================================
  // EXTRACT NOTE DETAIL OBJECT
  // ===========================================================================

  Map<String, dynamic> _extractObject(
      dynamic response,
      ) {
    dynamic value = response;

    if (value == null) {
      throw StateError(
        'The note detail response is empty.',
      );
    }

    value = _decodeJsonString(value);

    if (value is List) {
      if (value.isEmpty) {
        throw StateError(
          'The requested note was not found.',
        );
      }

      value = value.first;
    }

    if (value is! Map) {
      throw StateError(
        'The note detail response has an invalid format.',
      );
    }

    final Map<String, dynamic> root =
    _convertMap(value);

    final dynamic data =
    _getValueIgnoreCase(
      root,
      'data',
    );

    if (data is Map) {
      final Map<String, dynamic> dataMap =
      _convertMap(data);

      final dynamic nestedNote =
      _firstValueIgnoreCase(
        dataMap,
        <String>[
          'note',
          'item',
          'record',
          'result',
        ],
      );

      if (nestedNote is Map) {
        return _convertMap(
          nestedNote,
        );
      }

      return dataMap;
    }

    if (data is List &&
        data.isNotEmpty &&
        data.first is Map) {
      return _convertMap(
        data.first as Map,
      );
    }

    final dynamic nestedNote =
    _firstValueIgnoreCase(
      root,
      <String>[
        'note',
        'item',
        'record',
        'result',
      ],
    );

    if (nestedNote is Map) {
      return _convertMap(
        nestedNote,
      );
    }

    if (nestedNote is List &&
        nestedNote.isNotEmpty &&
        nestedNote.first is Map) {
      return _convertMap(
        nestedNote.first as Map,
      );
    }

    return root;
  }

  // ===========================================================================
  // EXTRACT SAVED NOTE ID
  // ===========================================================================

  int _extractSavedNoteId(
      dynamic value, {
        int depth = 0,
      }) {
    if (value == null ||
        depth > 12) {
      return 0;
    }

    if (value is int) {
      return value > 0 ? value : 0;
    }

    if (value is num) {
      final int result =
      value.toInt();

      return result > 0 ? result : 0;
    }

    if (value is String) {
      final String text =
      value.trim();

      if (text.isEmpty) {
        return 0;
      }

      final int directId =
      _positiveInt(text);

      if (directId > 0) {
        return directId;
      }

      /*
       * Handles JSON returned as a string:
       *
       * "{\"data\":{\"id\":25}}"
       */
      try {
        final dynamic decoded =
        jsonDecode(text);

        final int decodedId =
        _extractSavedNoteId(
          decoded,
          depth: depth + 1,
        );

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
      final RegExp idPattern =
      RegExp(
        r'(?:"?(?:note[_\s-]?id|new[_\s-]?id|saved[_\s-]?id|'
        r'inserted[_\s-]?id|created[_\s-]?id|record[_\s-]?id|id)"?)'
        r'\s*[:=]\s*"?(\d+)"?',
        caseSensitive: false,
      );

      final RegExpMatch? match =
      idPattern.firstMatch(text);

      if (match != null) {
        return _positiveInt(
          match.group(1),
        );
      }

      return 0;
    }

    if (value is List) {
      for (final dynamic item in value) {
        final int foundId =
        _extractSavedNoteId(
          item,
          depth: depth + 1,
        );

        if (foundId > 0) {
          return foundId;
        }
      }

      return 0;
    }

    if (value is! Map) {
      return 0;
    }

    final Map<String, dynamic> map =
    _convertMap(value);

    /*
     * Search explicit ID properties first.
     */
    for (final MapEntry<String, dynamic> entry
    in map.entries) {
      final String normalizedKey =
      _normalizeKey(entry.key);

      final bool isIdField =
          normalizedKey == 'id' ||
              normalizedKey == 'noteid' ||
              normalizedKey == 'newid' ||
              normalizedKey == 'newnoteid' ||
              normalizedKey == 'savedid' ||
              normalizedKey == 'savednoteid' ||
              normalizedKey == 'insertid' ||
              normalizedKey == 'insertedid' ||
              normalizedKey ==
                  'insertednoteid' ||
              normalizedKey ==
                  'createdid' ||
              normalizedKey ==
                  'creatednoteid' ||
              normalizedKey ==
                  'recordid' ||
              normalizedKey ==
                  'resultid' ||
              normalizedKey ==
                  'returnid' ||
              normalizedKey ==
                  'outputid';

      if (!isIdField) {
        continue;
      }

      final int foundId =
      _positiveInt(
        entry.value,
      );

      if (foundId > 0) {
        return foundId;
      }

      final int nestedId =
      _extractSavedNoteId(
        entry.value,
        depth: depth + 1,
      );

      if (nestedId > 0) {
        return nestedId;
      }
    }

    /*
     * Search common response wrappers.
     */
    const List<String> wrapperKeys =
    <String>[
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

    for (final String wrapperKey
    in wrapperKeys) {
      dynamic nestedValue;

      for (final MapEntry<String, dynamic> entry
      in map.entries) {
        if (_normalizeKey(entry.key) ==
            wrapperKey) {
          nestedValue = entry.value;
          break;
        }
      }

      if (nestedValue == null) {
        continue;
      }

      final int foundId =
      _extractSavedNoteId(
        nestedValue,
        depth: depth + 1,
      );

      if (foundId > 0) {
        return foundId;
      }
    }

    /*
     * Search any remaining nested maps and lists.
     * Plain numbers under fields such as statusCode
     * are ignored.
     */
    for (final dynamic nestedValue
    in map.values) {
      if (nestedValue is! Map &&
          nestedValue is! List) {
        continue;
      }

      final int foundId =
      _extractSavedNoteId(
        nestedValue,
        depth: depth + 1,
      );

      if (foundId > 0) {
        return foundId;
      }
    }

    return 0;
  }

  // ===========================================================================
  // NOTE MAPPER
  // ===========================================================================

  NoteEntity _noteFromJson(
      Map<String, dynamic> json,
      ) {
    return NoteEntity(
      id: _toInt(
        _firstValueIgnoreCase(
          json,
          <String>[
            'id',
            'noteId',
          ],
        ),
      ),
      folderId: _toInt(
        _firstValueIgnoreCase(
          json,
          <String>[
            'folderId',
          ],
        ),
      ),
      title: _firstValueIgnoreCase(
        json,
        <String>[
          'title',
          'noteTitle',
        ],
      )
          ?.toString() ??
          '',
      content: _parseContent(
        _firstValueIgnoreCase(
          json,
          <String>[
            'content',
            'contentJson',
            'blocks',
          ],
        ),
      ),
      isPinned: _toBool(
        _firstValueIgnoreCase(
          json,
          <String>[
            'isPinned',
            'pinned',
          ],
        ),
      ),
      isArchived: _toBool(
        _firstValueIgnoreCase(
          json,
          <String>[
            'isArchived',
            'archived',
          ],
        ),
      ),
      isLocked: _toBool(
        _firstValueIgnoreCase(
          json,
          <String>[
            'isLocked',
            'locked',
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // CONTENT PARSER
  // ===========================================================================

  List<Map<String, dynamic>> _parseContent(
      dynamic value,
      ) {
    if (value == null) {
      return <Map<String, dynamic>>[];
    }

    dynamic parsedValue = value;

    if (parsedValue is String) {
      final String cleanValue =
      parsedValue.trim();

      if (cleanValue.isEmpty) {
        return <Map<String, dynamic>>[];
      }

      try {
        parsedValue =
            jsonDecode(cleanValue);
      } catch (_) {
        /*
         * Support older content saved as plain text.
         */
        return <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'legacy-text',
            'type': 'text',
            'text': cleanValue,
            'displayOrder': 1,
          },
        ];
      }
    }

    if (parsedValue is Map) {
      return <Map<String, dynamic>>[
        _convertMap(parsedValue),
      ];
    }

    if (parsedValue is! List) {
      return <Map<String, dynamic>>[];
    }

    return parsedValue
        .whereType<Map>()
        .map(
          (Map<dynamic, dynamic> block) {
        return _convertMap(block);
      },
    )
        .toList(
      growable: false,
    );
  }

  // ===========================================================================
  // GENERAL HELPERS
  // ===========================================================================

  dynamic _decodeJsonString(
      dynamic value,
      ) {
    if (value is! String) {
      return value;
    }

    final String text =
    value.trim();

    if (text.isEmpty) {
      return value;
    }

    try {
      return jsonDecode(text);
    } catch (_) {
      return value;
    }
  }

  Map<String, dynamic> _convertMap(
      Map<dynamic, dynamic> map,
      ) {
    return map.map(
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
  }

  Map<String, dynamic> _deepCopyMap(
      Map<String, dynamic> source,
      ) {
    return source.map(
          (
          String key,
          dynamic value,
          ) {
        if (value is Map) {
          return MapEntry<String, dynamic>(
            key,
            _convertMap(value).map(
                  (
                  String childKey,
                  dynamic childValue,
                  ) {
                return MapEntry<String, dynamic>(
                  childKey,
                  childValue,
                );
              },
            ),
          );
        }

        if (value is List) {
          return MapEntry<String, dynamic>(
            key,
            value.map(
                  (dynamic item) {
                if (item is Map) {
                  return _convertMap(item);
                }

                return item;
              },
            ).toList(
              growable: false,
            ),
          );
        }

        return MapEntry<String, dynamic>(
          key,
          value,
        );
      },
    );
  }

  dynamic _getValueIgnoreCase(
      Map<String, dynamic> map,
      String wantedKey,
      ) {
    final String normalizedWantedKey =
    _normalizeKey(wantedKey);

    for (final MapEntry<String, dynamic> entry
    in map.entries) {
      if (_normalizeKey(entry.key) ==
          normalizedWantedKey) {
        return entry.value;
      }
    }

    return null;
  }

  dynamic _firstValueIgnoreCase(
      Map<String, dynamic> map,
      List<String> keys,
      ) {
    for (final String key in keys) {
      final dynamic value =
      _getValueIgnoreCase(
        map,
        key,
      );

      if (value != null) {
        return value;
      }
    }

    return null;
  }

  String _normalizeKey(
      String key,
      ) {
    return key
        .trim()
        .toLowerCase()
        .replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
  }

  int _positiveInt(
      dynamic value,
      ) {
    final int parsed =
    _toInt(value);

    return parsed > 0 ? parsed : 0;
  }

  int _toInt(
      dynamic value,
      ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString().trim() ?? '',
    ) ??
        0;
  }

  bool _toBool(
      dynamic value,
      ) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final String text =
        value
            ?.toString()
            .trim()
            .toLowerCase() ??
            '';

    return text == 'true' ||
        text == '1' ||
        text == 'yes' ||
        text == 'y';
  }

  String _fileNameFromPath(
      String filePath,
      ) {
    final String normalizedPath =
    filePath.replaceAll(
      '\\',
      '/',
    );

    final List<String> parts =
    normalizedPath.split('/');

    final String filename =
    parts.isNotEmpty
        ? parts.last.trim()
        : '';

    if (filename.isNotEmpty) {
      return filename;
    }

    return 'attachment';
  }

  String _responsePreview(
      dynamic response,
      ) {
    String text;

    try {
      text = jsonEncode(response);
    } catch (_) {
      text =
          response?.toString() ?? 'null';
    }

    const int maximumLength = 700;

    if (text.length <= maximumLength) {
      return text;
    }

    return '${text.substring(0, maximumLength)}...';
  }
}