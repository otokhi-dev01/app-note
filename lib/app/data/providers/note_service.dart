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
      final response = await _api.dio.get("/api/note", queryParameters: {
        if (folderId != null && folderId != 0) "FolderId": folderId,
      });

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

      // Compact debug logs for successful requests
      if (kDebugMode) {
        debugPrint("API Code: ${noteResponse.code}");
        debugPrint("API Message: ${noteResponse.message}");
        debugPrint("Active Notes: ${noteResponse.notes.length}");
        debugPrint("Archived Notes: ${noteResponse.archive.length}");
        debugPrint("Trash Notes: ${noteResponse.trash.length}");
      }

      return noteResponse;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("FETCH NOTES Error: $e");
      }
      rethrow;
    }
  }

  Future<List<NoteModel>> getTrashNotes() async {
    try {
      final response = await getNotes();
      return response.trash;
    } catch (e) {
      if (kDebugMode) debugPrint("GET TRASH Error: $e");
      return [];
    }
  }

  Future<NoteModel> getNoteDetail(int id) async {
    try {
      if (kDebugMode) debugPrint("[NOTE DETAIL API] GET /api/note/$id");
      
      final response = await _api.dio.get("/api/note/$id");
      
      if (kDebugMode) debugPrint("[NOTE DEBUG] Raw Detail Data: ${response.data}");

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

  Future<NoteModel> saveNote(int folderId, String title, {int noteId = 0, List<NoteBlock>? content}) async {
    if (kDebugMode) debugPrint("[NOTE DEBUG] saveNote START for NoteId: $noteId");
    
    final Map<String, dynamic> payload = {
      "NoteId": noteId,
      "FolderId": folderId,
      "Title": title,
    };
    
    if (content != null) {
      final List<Map<String, dynamic>> rawList = content.map((e) => e.toJson()).toList();
      final String jsonString = jsonEncode(rawList);
      
      // EXTREME RESILIENCE: Send content to every possible field name
      payload["ContentJson"] = jsonString; // Change back to String to see if server prefers it
      payload["Content"] = jsonString;
      payload["Body"] = jsonString;
      payload["NoteText"] = jsonString;
      payload["Description"] = jsonString;
      payload["NoteDescription"] = jsonString;
      payload["NoteContent"] = jsonString;
    }

    final response = await _api.dio.post("/api/note/save", data: payload);
    
    if (kDebugMode) debugPrint("[NOTE DEBUG] saveNote RESPONSE: ${response.data}");
    
    final note = _parseNoteFromResponse(response.data);
    if (note == null) {
      // If it's a 200 OK and code 200, but data is null, it's a success without content
      final responseData = response.data;
      if (responseData is Map && (responseData['code'] == 200 || responseData['Code'] == 200)) {
        if (kDebugMode) debugPrint("[NOTE DEBUG] saveNote SUCCESS (code 200) with empty data.");
        if (noteId != 0) return await getNoteDetail(noteId);
      }

      if (kDebugMode) debugPrint("[NOTE DEBUG] saveNote FAILED to parse response. Data: ${response.data}");
      
      if (noteId != 0) {
        return await getNoteDetail(noteId);
      } else {
        // For new notes where API returns null data, find the latest note in the folder
        final allNotes = await getNotes(folderId: folderId, refresh: true);
        if (allNotes.notes.isNotEmpty) {
          final sorted = List<NoteModel>.from(allNotes.notes);
          sorted.sort((a, b) => b.id.compareTo(a.id));
          return sorted.first;
        }
      }
      throw Exception("Failed to parse saved note and no fallback found");
    }
    return note;
  }

  Future<void> updateNoteState(int id, {bool? isPinned, bool? isArchived, bool? isLocked}) async {
    try {
      if (kDebugMode) debugPrint("[NOTE DEBUG] updateNoteState ID: $id, pinned: $isPinned, archived: $isArchived");
      
      final response = await _api.dio.post("/api/note/update-state", data: {
        "NoteId": id,
        "id": id, // resilience
        if (isPinned != null) "IsPinned": isPinned,
        if (isArchived != null) "IsArchived": isArchived,
        if (isLocked != null) "IsLocked": isLocked,
      });

      if (kDebugMode) debugPrint("[NOTE DEBUG] updateNoteState RESPONSE: ${response.statusCode}");
    } catch (e) {
      if (kDebugMode) debugPrint("[NOTE DEBUG] updateNoteState ERROR: $e");
      rethrow;
    }
  }

  Future<void> deleteRestoreNote(int id, bool isDelete) async {
    try {
      if (kDebugMode) debugPrint("[NOTE DEBUG] deleteRestoreNote ID: $id, isDelete: $isDelete");
      
      // We send multiple ID variants to be resilient to backend naming inconsistencies
      final response = await _api.dio.post("/api/note/delete-restore", data: {
        "NoteId": id,
        "id": id,
        "Id": id,
        "isDelete": isDelete,
        "IsDelete": isDelete,
      });
      
      if (kDebugMode) debugPrint("[NOTE DEBUG] deleteRestoreNote RESPONSE: ${response.statusCode} ${response.data}");
    } catch (e) {
      if (kDebugMode) debugPrint("[NOTE DEBUG] deleteRestoreNote FATAL ERROR: $e");
      rethrow;
    }
  }

  Future<void> deleteNotePermanently(int id) async {
    try {
      if (kDebugMode) debugPrint("[NOTE DEBUG] deleteNotePermanently ID: $id");
      await _api.dio.post("/api/note/permanent-delete", data: {
        "NoteId": id,
        "id": id,
      });
    } catch (e) {
      if (kDebugMode) debugPrint("[NOTE DEBUG] deleteNotePermanently ERROR: $e");
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

  Future<Map<String, dynamic>> uploadAttachment(int noteId, String filePath, String blockId, int displayOrder) async {
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
    
    final response = await _api.dio.post("/api/note/attachment", data: formData);
    
    if (kDebugMode) debugPrint("[NOTE DEBUG] UPLOAD RESPONSE: ${response.data}");
    
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
