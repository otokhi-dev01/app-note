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
      final response = await _api.dio.get("/api/note");
      final data = response.data['data'];
      if (data == null) return [];
      
      final List trashList = data['trash'] ?? [];
      final List archiveList = data['archive'] ?? [];
      
      final List combined = [...trashList, ...archiveList];
      
      return combined
          .map((e) => NoteModel.fromJson(e))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint("GET TRASH Error: $e");
      }
      return [];
    }
  }

  Future<NoteModel> getNoteDetail(int id) async {
    final response = await _api.dio.get("/api/note/$id");
    return NoteModel.fromJson(response.data['data']);
  }

  Future<void> saveNote(int folderId, String title, {int noteId = 0}) async {
    await _api.dio.post("/api/note/save", data: {
      "NoteId": noteId,
      "FolderId": folderId,
      "Title": title,
    });
  }

  Future<void> saveContent(int noteId, String title, List<NoteBlock> content) async {
    await _api.dio.post("/api/note/save-content", data: {
      "NoteId": noteId,
      "Title": title,
      "Content": jsonEncode(content.map((e) => e.toJson()).toList()),
    });
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

  Future<void> uploadAttachment(int noteId, String filePath, String blockId, int displayOrder) async {
    dio.FormData formData = dio.FormData.fromMap({
      "Id": noteId.toString(),
      "File": await dio.MultipartFile.fromFile(filePath),
      "BlockId": blockId,
      "DisplayOrder": displayOrder.toString(),
    });
    await _api.dio.post("/api/note/attachment", data: formData);
  }
}
