import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart' hide Response;
import '../models/note_model.dart';
import 'api_service.dart';

class NoteService extends GetxService {
  final ApiService _api = Get.find<ApiService>();

  Future<NoteResponse> getNotes({int? folderId}) async {
    try {
      final response = await _api.dio.get("/api/note", queryParameters: {
        if (folderId != null && folderId != 0) "FolderId": folderId,
      });

      // Safely handle data decoding
      final responseData = response.data;
      if (kDebugMode) {
        debugPrint("RAW API RESPONSE: $responseData");
      }
      Map<String, dynamic> mappedData;
      if (responseData is String) {
        mappedData = jsonDecode(responseData);
      } else if (responseData is Map) {
        mappedData = Map<String, dynamic>.from(responseData);
      } else {
        throw Exception("Invalid response format: ${responseData.runtimeType}");
      }

      final noteResponse = NoteResponse.fromJson(mappedData);

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
      if (kDebugMode) debugPrint("[NOTE DETAIL ERROR] $e");
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
      
      // If it's a wrapper with code/message but the note might be in a list under 'data'
      if (map.containsKey('code') && map.containsKey('message')) {
        // We already checked 'data' above, so if we reach here, it's not in 'data'
      }
    }

    // Handle List response (pick first item)
    if (data is List) {
      if (data.isEmpty) return null;
      return _parseNoteFromResponse(data.first);
    }

    return null;
  }

  Future<NoteModel> saveNote(int folderId, String title, {int noteId = 0}) async {
    if (kDebugMode) debugPrint("[NOTE DEBUG] saveNote START for NoteId: $noteId");
    final response = await _api.dio.post("/api/note/save", data: {
      "NoteId": noteId,
      "FolderId": folderId,
      "Title": title,
    });
    
    if (kDebugMode) debugPrint("[NOTE DEBUG] saveNote RESPONSE: ${response.data}");
    
    final note = _parseNoteFromResponse(response.data);
    if (note == null) {
      if (kDebugMode) debugPrint("[NOTE DEBUG] saveNote FAILED to parse response. Attempting fallback fetch.");
      if (noteId != 0) {
        return await getNoteDetail(noteId);
      }
      throw Exception("Failed to parse saved note");
    }
    return note;
  }

  Future<void> saveContent(int noteId, int folderId, String title, List<NoteBlock> content) async {
    final payload = {
      "NoteId": noteId,
      "FolderId": folderId,
      "Title": title,
      "Content": content.map((e) => e.toJson()).toList(),
    };

    if (kDebugMode) {
      debugPrint("[NOTE SAVE] URL: /api/note/save-content");
      debugPrint("[NOTE SAVE] METHOD: POST");
      debugPrint("[NOTE SAVE] NOTE ID: $noteId");
      debugPrint("[NOTE SAVE] FOLDER ID: $folderId");
      debugPrint("[NOTE SAVE] TITLE: $title");
      debugPrint("[NOTE SAVE] CONTENT COUNT: ${content.length}");
    }

    final endpoints = [
      "/api/note/save-content",
      "/api/note/detail/save-content",
      "/api/note/$noteId/save-content",
    ];

    for (var url in endpoints) {
      try {
        if (kDebugMode) debugPrint("[NOTE DEBUG] Trying save: POST $url");
        final response = await _api.dio.post(
          url, 
          data: payload,
          queryParameters: {"NoteId": noteId},
        );
        if (response.statusCode == 200) {
          if (kDebugMode) debugPrint("[NOTE SAVE RESPONSE] STATUS: 200, BODY: ${response.data}");
          return;
        }
      } catch (e) {
        if (kDebugMode) debugPrint("[NOTE SAVE ERROR] Endpoint $url failed: $e");
      }
    }

    throw Exception("All save variations failed for NoteId: $noteId.");
  }

  Future<void> updateNoteState(int id, {bool? isPinned, bool? isArchived, bool? isLocked}) async {
    await _api.dio.post("/api/note/update-state", data: {
      "NoteId": id,
      if (isPinned != null) "IsPinned": isPinned,
      if (isArchived != null) "IsArchived": isArchived,
      if (isLocked != null) "IsLocked": isLocked,
    });
  }

  Future<void> deleteRestoreNote(int id, bool isDelete) async {
    await _api.dio.post("/api/note/delete-restore", data: {
      "NoteId": id,
      "isDelete": isDelete,
    });
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
