import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart' hide Response;
import '../models/note_model.dart';
import 'api_service.dart';

class NoteService extends GetxService {
  final ApiService _api = Get.find<ApiService>();

  Future<List<NoteModel>> getNotes({int? folderId}) async {
    try {
      final response = await _api.dio.get("/api/note", queryParameters: {
        if (folderId != null) "FolderId": folderId,
      });
      
      debugPrint("GET NOTES Response: ${response.data}");
      
      final data = response.data['data'];
      if (data == null) return [];
      
      // We combine 'note' (active) and 'archive' (hidden/deleted) to show "all data"
      final List noteList = data['note'] ?? [];
      final List archiveList = data['archive'] ?? [];
      
      final List combined = [...noteList, ...archiveList];
      
      return combined
          .map((e) => NoteModel.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint("GET NOTES Error: $e");
      return [];
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
      debugPrint("GET TRASH Error: $e");
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
