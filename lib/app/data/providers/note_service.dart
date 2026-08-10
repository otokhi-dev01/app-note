import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart' hide Response;
import '../models/note_model.dart';
import 'api_service.dart';

class NoteService extends GetxService {
  final ApiService _api = Get.find<ApiService>();

  NoteResponse? _cachedResponse;

  Future<NoteResponse> getNotes({int? folderId, bool refresh = false}) async {
    if (_cachedResponse != null && !refresh && folderId == null) {
      return _cachedResponse!;
    }

    try {
      final response = await _api.dio.get(
        "/api/note",
        queryParameters: {
          if (folderId != null && folderId != 0) "FolderId": folderId,
        },
      );

      // Safely handle data decoding
      final responseData = response.data;
      Map<String, dynamic> mappedData;
      if (responseData is String) {
        mappedData = jsonDecode(responseData);
      } else if (responseData is Map) {
        mappedData = Map<String, dynamic>.from(responseData);
      } else {
        throw Exception("Invalid response format: ${responseData.runtimeType}");
      }

      final noteResponse = NoteResponse.fromJson(mappedData);

      // Cache the full response if it's not a filtered request
      if (folderId == null || folderId == 0) {
        _cachedResponse = noteResponse;
      }

      if (kDebugMode) {
        debugPrint("API Code: ${noteResponse.code}");
        debugPrint("API Message: ${noteResponse.message}");
        debugPrint("Active Notes: ${noteResponse.notes.length}");
        debugPrint("Archived Notes: ${noteResponse.archive.length}");
        debugPrint("Trash Notes: ${noteResponse.trash.length}");
      }

      return noteResponse;
    } catch (e) {
      if (kDebugMode) debugPrint("GET TRASH Error: $e");
      return NoteResponse(
        code: 0,
        message: 'Failed to load notes',
        data: NoteData(notes: [], archive: [], trash: []),
      );
    }
  }

  Future<List<NoteModel>> getTrashNotes({bool refresh = false}) async {
    try {
      final noteResponse = await getNotes(refresh: refresh);
      return noteResponse.trash;
    } catch (e) {
      if (kDebugMode) debugPrint("GET TRASH NOTES Error: $e");
      return [];
    }
  }

  Future<NoteModel> getNoteDetail(int id) async {
    try {
      if (kDebugMode) debugPrint("[NOTE DETAIL API] GET /api/note/$id");

      final response = await _api.dio.get("/api/note/$id");

      if (kDebugMode)
        debugPrint("[NOTE DEBUG] Raw Detail Data: ${response.data}");

      if (response.statusCode == 200) {
        final note = _parseNoteFromResponse(response.data);
        if (note != null) {
          if (kDebugMode) {
            debugPrint("[NOTE DETAIL API] 200 OK");
            debugPrint("[NOTE DETAIL] Loaded NoteId: ${note.id}");
          }
          return note;
        }
      }

      throw Exception("Failed to load note detail for ID: $id");
    } catch (e) {
      if (kDebugMode) {
        if (e is dio.DioException && e.response?.statusCode == 404) {
          debugPrint("[NOTE DETAIL ERROR] 404 - Note Not Found: $id");
        } else {
          debugPrint("[NOTE DETAIL ERROR] $e");
        }
      }
      rethrow;
    }
  }

  NoteModel? _parseNoteFromResponse(dynamic data) {
    if (data == null) return null;

    // Handle String response
    if (data is String) {
      try {
        return _parseNoteFromResponse(jsonDecode(data));
      } catch (_) {
        return null;
      }
    }

    // Handle wrapping in { "data": ... } or { "note": ... }
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);

      // If it has a 'data' field, recurse into it
      if (map.containsKey('data') && map['data'] != null) {
        return _parseNoteFromResponse(map['data']);
      }

      // If it has a 'note' field, recurse into it
      if (map.containsKey('note') && map['note'] != null) {
        return _parseNoteFromResponse(map['note']);
      }

      // Check for NoteId or id to identify it as a Note object
      if (map.containsKey('NoteId') || map.containsKey('id')) {
        return NoteModel.fromJson(map);
      }
    }

    // Handle List response (pick first item)
    if (data is List) {
      if (data.isEmpty) return null;
      return _parseNoteFromResponse(data.first);
    }

    return null;
  }

  Future<NoteModel> saveNote(
    int folderId,
    String title, {
    int noteId = 0,
    List<NoteBlock>? content,
  }) async {
    if (kDebugMode)
      debugPrint("[NOTE DEBUG] saveNote START for NoteId: $noteId");

    if (folderId == 0) {
      throw ArgumentError(
        'FolderId must be provided and non-zero when saving a note',
      );
    }

    // Build payload but omit NoteId when creating a new note (server expects it absent or null)
    final Map<String, dynamic> payload = {"FolderId": folderId, "Title": title};

    if (noteId != 0) payload["NoteId"] = noteId;

    List<dynamic>? contentList;
    if (content != null) {
      // Normalize each block's JSON to include multiple common key variants
      // so the backend can accept different shapes (Type/Text vs type/text).
      contentList = content.map((e) {
        final Map<String, dynamic> m = Map<String, dynamic>.from(e.toJson());
        // Text blocks: ensure both 'Text' and 'text' are present and support
        // string-encoded Delta JSON for backend compatibility.
        if (e.runtimeType.toString().contains('TextBlock')) {
          final raw =
              m['Text'] ??
              m['text'] ??
              m['content'] ??
              m['Value'] ??
              m['value'];
          final String textValue;
          if (raw is List || raw is Map) {
            textValue = jsonEncode(raw);
          } else {
            textValue = raw?.toString() ?? '';
          }

          dynamic parsedText = textValue;
          if (textValue.trimLeft().startsWith('[') ||
              textValue.trimLeft().startsWith('{')) {
            try {
              parsedText = jsonDecode(textValue);
            } catch (_) {
              parsedText = textValue;
            }
          }

          final plainText = _extractPlainTextFromDelta(parsedText);

          m['Type'] = m['Type'] ?? m['type'] ?? 'text';
          m['type'] = m['type'] ?? m['Type'] ?? 'text';
          m['Text'] = textValue;
          m['text'] = textValue;
          m['Content'] = textValue;
          m['content'] = textValue;
          m['Body'] = plainText;
          m['body'] = plainText;
          m['NoteText'] = plainText;
          m['noteText'] = plainText;
          m['ContentText'] = plainText;
          m['contentText'] = plainText;
        }
        // Attachment blocks: normalize common fields
        if (e.runtimeType.toString().contains('AttachmentBlock')) {
          m['Type'] = m['Type'] ?? m['type'] ?? 'attachment';
          m['type'] = m['type'] ?? m['Type'] ?? 'attachment';
          m['Url'] = m['Url'] ?? m['url'] ?? m['FilePath'] ?? m['filePath'];
          m['url'] = m['url'] ?? m['Url'];
        }
        return m;
      }).toList();

      // Send multiple variants for resilience. Prefer ContentJson as an encoded string
      // because some backend endpoints expect ContentJson to be a JSON string.
      payload["Content"] = contentList;
      payload["ContentJson"] = jsonEncode(contentList);
      payload["ContentJsonString"] = jsonEncode(contentList);
      payload["Body"] = contentList
          .whereType<Map<String, dynamic>>()
          .where(
            (m) => (m["Type"] ?? m["type"])?.toString().toLowerCase() == 'text',
          )
          .map(
            (m) => (m['Body'] ?? m['body'] ?? m['Text'] ?? m['text'] ?? '')
                .toString(),
          )
          .join('\n')
          .trim();
      payload["NoteText"] = payload["Body"];
      payload["ContentText"] = payload["Body"];

      if (kDebugMode)
        debugPrint(
          '[NOTE DEBUG] Sample content payload: ${contentList.isNotEmpty ? contentList.first : {}}',
        );
    }

    dio.Response? response;

    // Helper to attempt a POST and return response or null on DioException
    Future<dio.Response?> tryPost(
      String path,
      Map<String, dynamic> body,
    ) async {
      try {
        if (kDebugMode)
          debugPrint(
            '[NOTE DEBUG] POST $path payload variant: ${body.keys.toList()}',
          );
        final r = await _api.dio.post(path, data: body);
        return r;
      } on dio.DioException catch (e) {
        if (kDebugMode)
          debugPrint(
            '[NOTE DEBUG] POST $path failed: ${e.response?.statusCode} ${e.response?.data}',
          );
        return e.response;
      }
    }

    // Try multiple payload variants to be resilient to backend expectations
    // Variant A: Content list + ContentJson as encoded string (current)
    response = await tryPost('/api/note/save-content', payload);

    // Variant B: If save-content gives a 400 due to Content validation, retry
    // without Content and with ContentJson only.
    if (response != null && response.statusCode == 400) {
      final altPayload = Map<String, dynamic>.from(payload)
        ..remove('Content')
        ..remove('ContentJson')
        ..remove('ContentJsonString');
      if (contentList != null) {
        altPayload['ContentJson'] = jsonEncode(contentList);
        altPayload['ContentJsonString'] = jsonEncode(contentList);
      }
      if (kDebugMode)
        debugPrint('[NOTE DEBUG] Retrying save-content without Content');
      response = await tryPost('/api/note/save-content', altPayload);
    }

    // If backend returned 404, null response, or still failed, try alternative variants
    if (response == null ||
        response.statusCode == 404 ||
        response.statusCode == 400 ||
        (response.data is Map &&
            (response.data['code'] == 404 ||
                response.data['message'] == 'Note not found.'))) {
      // Variant C: ContentJson as actual list (not string)
      final altPayload = Map<String, dynamic>.from(payload);
      if (contentList != null) altPayload['ContentJson'] = contentList;
      if (kDebugMode)
        debugPrint('[NOTE DEBUG] Retrying with ContentJson as list');
      response = await tryPost('/api/note/save-content', altPayload);
    }

    if (response == null ||
        response.statusCode == 404 ||
        response.statusCode == 400 ||
        (response.data is Map &&
            (response.data['code'] == 404 ||
                response.data['message'] == 'Note not found.' ||
                response.data['message'] == 'Folder not found.'))) {
      // Variant D: Try legacy endpoint '/api/note/save' with ContentJson list.
      final legacyPayload = Map<String, dynamic>.from(payload);
      if (contentList != null) legacyPayload['ContentJson'] = contentList;
      if (kDebugMode)
        debugPrint('[NOTE DEBUG] Retrying legacy endpoint /api/note/save');
      response = await tryPost('/api/note/save', legacyPayload);
    }

    if (response == null) {
      throw Exception('No response from server when attempting to save note');
    }

    if (kDebugMode)
      debugPrint("[NOTE DEBUG] saveNote RESPONSE: ${response.data}");

    // Try to parse the note from the response
    final note = _parseNoteFromResponse(response.data);
    if (note != null && note.id != 0) return note;

    // Fallback: check API code field for success and resolve created/updated note
    final responseData = response.data;
    bool isSuccess = false;
    if (responseData is Map) {
      final dynamic code = responseData['code'] ?? responseData['Code'];
      if (code == 200 || code == 201 || code.toString() == "200")
        isSuccess = true;
    }

    if (isSuccess) {
      if (noteId != 0) {
        try {
          await Future.delayed(const Duration(milliseconds: 500));
          return await getNoteDetail(noteId);
        } catch (e) {
          if (kDebugMode)
            debugPrint(
              "[NOTE DEBUG] saveNote fallback getNoteDetail failed: $e",
            );
          return NoteModel(
            id: noteId,
            folderId: folderId,
            folderName: '',
            title: title,
            content: content ?? [],
          );
        }
      } else {
        await Future.delayed(const Duration(milliseconds: 800));
        final allNotes = await getNotes(folderId: folderId, refresh: true);
        if (allNotes.notes.isNotEmpty) {
          final sorted = List<NoteModel>.from(allNotes.notes);
          sorted.sort((a, b) => b.id.compareTo(a.id));
          return sorted.first;
        }
      }
    }

    throw Exception("Failed to parse saved note and no fallback found");
  }

  String _extractPlainTextFromDelta(dynamic value) {
    if (value is String) {
      return value;
    }
    if (value is List) {
      return value.map((item) {
        if (item is Map && item.containsKey('insert')) {
          return item['insert']?.toString() ?? '';
        }
        return item?.toString() ?? '';
      }).join();
    }
    if (value is Map) {
      if (value.containsKey('insert')) {
        return value['insert']?.toString() ?? '';
      }
      return value.values.map((v) => _extractPlainTextFromDelta(v)).join();
    }
    return value?.toString() ?? '';
  }

  Future<void> updateNoteState(
    int id, {
    bool? isPinned,
    bool? isArchived,
    bool? isLocked,
  }) async {
    try {
      if (kDebugMode)
        debugPrint(
          "[NOTE DEBUG] updateNoteState ID: $id, pinned: $isPinned, archived: $isArchived",
        );

      final response = await _api.dio.post(
        "/api/note/update-state",
        data: {
          "NoteId": id,
          "id": id, // resilience
          if (isPinned != null) "IsPinned": isPinned,
          if (isArchived != null) "IsArchived": isArchived,
          if (isLocked != null) "IsLocked": isLocked,
        },
      );

      if (kDebugMode)
        debugPrint(
          "[NOTE DEBUG] updateNoteState RESPONSE: ${response.statusCode}",
        );
    } catch (e) {
      if (kDebugMode) debugPrint("[NOTE DEBUG] updateNoteState ERROR: $e");
      rethrow;
    }
  }

  Future<void> deleteRestoreNote(int id, bool isDelete) async {
    try {
      if (kDebugMode)
        debugPrint(
          "[NOTE DEBUG] deleteRestoreNote ID: $id, isDelete: $isDelete",
        );

      // We send multiple ID variants to be resilient to backend naming inconsistencies
      final response = await _api.dio.post(
        "/api/note/delete-restore",
        data: {
          "NoteId": id,
          "id": id,
          "Id": id,
          "isDelete": isDelete,
          "IsDelete": isDelete,
        },
      );

      if (kDebugMode)
        debugPrint(
          "[NOTE DEBUG] deleteRestoreNote RESPONSE: ${response.statusCode} ${response.data}",
        );
    } catch (e) {
      if (kDebugMode)
        debugPrint("[NOTE DEBUG] deleteRestoreNote FATAL ERROR: $e");
      rethrow;
    }
  }

  Future<void> deleteNotePermanently(int id) async {
    try {
      if (kDebugMode) debugPrint("[NOTE DEBUG] deleteNotePermanently ID: $id");
      await _api.dio.post(
        "/api/note/permanent-delete",
        data: {"NoteId": id, "id": id},
      );
    } catch (e) {
      if (kDebugMode)
        debugPrint("[NOTE DEBUG] deleteNotePermanently ERROR: $e");
      rethrow;
    }
  }

  Future<void> emptyTrash() async {
    try {
      if (kDebugMode) debugPrint("[NOTE DEBUG] emptyTrash START");
      await _api.dio.post("/api/note/empty-trash");
    } catch (e) {
      if (kDebugMode) debugPrint("[NOTE DEBUG] emptyTrash ERROR: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadAttachment(
    int noteId,
    String filePath,
    String blockId,
    int displayOrder,
  ) async {
    dio.FormData formData = dio.FormData.fromMap({
      "Id": noteId.toString(),
      "File": await dio.MultipartFile.fromFile(filePath),
      "BlockId": blockId,
      "DisplayOrder": displayOrder.toString(),
    });

    if (kDebugMode) {
      debugPrint("[NOTE DEBUG] UPLOAD ATTACHMENT START");
      debugPrint("[NOTE DEBUG] NoteId: $noteId, BlockId: $blockId");
    }

    final response = await _api.dio.post(
      "/api/note/attachment",
      data: formData,
    );

    if (kDebugMode)
      debugPrint("[NOTE DEBUG] UPLOAD RESPONSE: ${response.data}");

    final responseData = response.data;
    if (responseData is Map) {
      if (responseData['data'] != null) {
        return Map<String, dynamic>.from(responseData['data']);
      }
      return Map<String, dynamic>.from(responseData);
    }
    return {};
  }
}
