import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart' hide Response;
import '../models/note_model.dart';
import 'api_service.dart';

class NoteService extends GetxService {
  final ApiService _api = Get.find<ApiService>();

  Future<NoteResponse> getNotes({int? folderId, bool refresh = false}) async {
    try {
      final response = await _api.dio.get(
        "/api/note",
        queryParameters: {
          if (folderId != null && folderId != 0) "folderId": folderId,
        },
      );
      return NoteResponse.fromJson(response.data);
    } catch (e, s) {
      debugPrint('[NOTE SERVICE] getNotes Error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  Future<NoteModel> getNoteDetail(int id) async {
    try {
      debugPrint('[NOTE DETAIL] GET NoteId=$id');
      final response = await _api.dio.get("/api/note/$id");

      final body = response.data;
      if (body is! Map) {
        throw Exception('Invalid note detail response.');
      }

      final dynamic rawData = body['data'] ?? body['Data'];
      debugPrint('[NOTE DETAIL] data type=${rawData.runtimeType}');

      dynamic rawNote;
      if (rawData is List) {
        if (rawData.isEmpty) {
          throw Exception('Note detail data list is empty.');
        }
        rawNote = rawData.first;
      } else if (rawData is Map) {
        rawNote = rawData;
      } else {
        throw Exception(
          'Unexpected note detail data type: ${rawData.runtimeType}',
        );
      }

      if (rawNote is! Map) {
        throw Exception('Invalid note object format.');
      }

      final note = NoteModel.fromJson(Map<String, dynamic>.from(rawNote));
      debugPrint(
        '[NOTE DETAIL] parsed NoteId=${note.id} blocks=${note.content.length}',
      );
      return note;
    } catch (e, s) {
      debugPrint('[NOTE SERVICE] getNoteDetail Error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  /// Full save flow: Metadata -> Uploads -> Content Sync
  Future<NoteModel> saveNote(
    int folderId,
    String title, {
    int noteId = 0,
    List<NoteBlock>? content,
  }) async {
    // 1. Metadata Save
    final confirmedId = await saveNoteMetadata(
      folderId: folderId,
      title: title,
      noteId: noteId,
    );

    if (content != null && content.isNotEmpty) {
      // 2. Final Content Sync
      await saveNoteContent(
        noteId: confirmedId,
        title: title,
        content: content,
      );
    }

    return await getNoteDetail(confirmedId);
  }

  /// Saves metadata (Title, FolderId) and returns the created/updated NoteId
  Future<int> saveNoteMetadata({
    required int folderId,
    required String title,
    int noteId = 0,
  }) async {
    try {
      debugPrint('[NOTE CREATE] POST /api/note/save');
      // Matches NoteSaveRequest: { noteId, folderId*, title }.
      final Map<String, dynamic> payload = {
        "folderId": folderId,
        "title": title,
      };
      if (noteId > 0) payload["noteId"] = noteId;

      final response = await _api.dio.post("/api/note/save", data: payload);
      final data = response.data;

      if (data is Map) {
        // Preferred: Backend returns NoteId in data
        final extractedId = _toInt(
          data['data']?['NoteId'] ??
              data['data']?['id'] ??
              data['NoteId'] ??
              data['id'],
        );
        if (extractedId > 0) {
          debugPrint('[NOTE CREATE] Created/Updated NoteId=$extractedId');
          return extractedId;
        }
      }

      if (noteId > 0) return noteId;

      // Temporary Workaround: Fetch list if backend returns null data on create
      debugPrint(
        '[NOTE CREATE] Backend returned null data. Attempting to resolve NoteId from list.',
      );
      final list = await getNotes(folderId: folderId, refresh: true);
      if (list.notes.isNotEmpty) {
        final sorted = List<NoteModel>.from(list.notes)
          ..sort((a, b) => b.id.compareTo(a.id));
        return sorted.first.id;
      }

      throw Exception("Failed to resolve NoteId after save");
    } catch (e, s) {
      debugPrint('[NOTE SERVICE] saveNoteMetadata Error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  /// Saves the structured content blocks for an existing NoteId
  Future<void> saveNoteContent({
    required int noteId,
    required String title,
    required List<NoteBlock> content,
  }) async {
    try {
      debugPrint(
        '[NOTE CONTENT] Saving NoteId=$noteId blocks=${content.length}',
      );

      final payload = {
        "id": noteId,
        "title": title,
        "content": content.map((e) => e.toJson()).toList(),
      };

      await _api.dio.post("/api/note/save-content", data: payload);
      debugPrint('[NOTE CONTENT] Success');
    } catch (e, s) {
      debugPrint('[NOTE SERVICE] saveNoteContent Error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadAttachment(
    int noteId,
    String filePath,
    String blockId,
    int displayOrder,
  ) async {
    try {
      debugPrint('[ATTACHMENT] Upload BlockId=$blockId for NoteId=$noteId');
      dio.FormData formData = dio.FormData.fromMap({
        "Id": noteId.toString(),
        "File": await dio.MultipartFile.fromFile(filePath),
        "BlockId": blockId,
        "DisplayOrder": displayOrder.toString(),
      });

      final response = await _api.dio.post(
        "/api/note/attachment",
        data: formData,
      );

      debugPrint('[ATTACHMENT RAW RESPONSE] ${response.data}');
      final body = response.data;
      if (body is! Map) throw Exception('Invalid upload response');

      final outerData = body['data'];
      if (outerData is! Map) throw Exception('Invalid upload response data');

      final records = outerData['data'];
      if (records is List && records.isNotEmpty) {
        final record = Map<String, dynamic>.from(records.first);

        final attachmentId = _toInt(
          record['AttachmentId'] ?? record['attachmentId'] ?? record['id'],
        );
        final path = _toString(
          record['FilePath'] ?? record['filePath'] ?? record['url'],
        );

        debugPrint(
          '[ATTACHMENT] Upload Success. AttachmentId=$attachmentId FilePath=$path',
        );
        return {
          'AttachmentId': attachmentId,
          'FilePath': path,
          'BlockId': blockId,
        };
      }

      // Fallback for different response shape
      final attachmentId = _toInt(
        outerData['AttachmentId'] ?? body['AttachmentId'],
      );
      final path = _toString(outerData['FilePath'] ?? body['FilePath']);

      debugPrint(
        '[ATTACHMENT] Upload Success (Fallback). AttachmentId=$attachmentId',
      );
      return {
        'AttachmentId': attachmentId,
        'FilePath': path,
        'BlockId': blockId,
      };
    } catch (e, s) {
      debugPrint('[NOTE SERVICE] uploadAttachment Error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  /// Standardized state update API — POST /api/note/update-state
  ///
  /// Matches NoteUpdateStateRequest: { id, isPinned?, isArchived?, isLocked? }.
  /// Note: the DTO has no isDelete field — use [deleteRestoreNote] instead.
  Future<void> updateNoteState(
    int id, {
    bool? isPinned,
    bool? isArchived,
    bool? isLocked,
  }) async {
    try {
      debugPrint('[NOTE STATE] POST /api/note/update-state NoteId=$id');
      final Map<String, dynamic> payload = {"id": id};
      if (isPinned != null) payload["isPinned"] = isPinned;
      if (isArchived != null) payload["isArchived"] = isArchived;
      if (isLocked != null) payload["isLocked"] = isLocked;

      await _api.dio.post("/api/note/update-state", data: payload);
    } catch (e, s) {
      debugPrint('[NOTE SERVICE] updateNoteState Error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  /// Soft-deletes or restores a note — POST /api/note/delete-restore
  ///
  /// Matches NoteDeleteOrRestoreRequest: { id, isDelete }.
  Future<void> deleteRestoreNote(int id, bool isDelete) async {
    try {
      debugPrint(
        '[NOTE DELETE] POST /api/note/delete-restore NoteId=$id isDelete=$isDelete',
      );
      await _api.dio.post(
        "/api/note/delete-restore",
        data: {"id": id, "isDelete": isDelete},
      );
    } catch (e, s) {
      debugPrint('[NOTE SERVICE] deleteRestoreNote Error: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  /// Not supported: the API exposes no /api/note/permanent-delete route.
  /// See [ApiCapabilities.permanentDelete].
  Future<void> deleteNotePermanently(int id) async {
    throw const ApiUnsupportedException(
      'Permanently deleting a note is not available on the server yet.',
    );
  }

  /// Not supported: the API exposes no /api/note/empty-trash route.
  /// See [ApiCapabilities.permanentDelete].
  Future<void> emptyTrash() async {
    throw const ApiUnsupportedException(
      'Emptying the trash is not available on the server yet.',
    );
  }

  Future<List<NoteModel>> getTrashNotes() async {
    try {
      final response = await getNotes();
      return response.trash;
    } catch (e) {
      return [];
    }
  }
}

class NoteResponse {
  final int code;
  final String message;
  final List<NoteModel> notes;
  final List<NoteModel> archive;
  final List<NoteModel> trash;

  NoteResponse({
    required this.code,
    required this.message,
    required this.notes,
    required this.archive,
    required this.trash,
  });

  factory NoteResponse.fromJson(Map<String, dynamic> json) {
    final dynamic rawData = json['data'];
    List<NoteModel> active = [];
    List<NoteModel> archived = [];
    List<NoteModel> deleted = [];

    void categorize(List<NoteModel> all) {
      active = all.where((n) => !n.isArchived && !n.isDeleted).toList();
      archived = all.where((n) => n.isArchived && !n.isDeleted).toList();
      deleted = all.where((n) => n.isDeleted).toList();
    }

    if (rawData is List) {
      categorize(
        rawData
            .map((e) => NoteModel.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
    } else if (rawData is Map) {
      final List rawNotes = (rawData['note'] ?? rawData['notes'] ?? []) as List;
      final List rawArchive =
          (rawData['archive'] ?? rawData['archived'] ?? []) as List;
      final List rawTrash =
          (rawData['trash'] ?? rawData['deleted'] ?? []) as List;

      if (rawNotes.isNotEmpty || rawArchive.isNotEmpty || rawTrash.isNotEmpty) {
        active = rawNotes
            .map((e) => NoteModel.fromJson(Map<String, dynamic>.from(e)))
            .where((n) => !n.isDeleted && !n.isArchived)
            .toList();
        archived = rawArchive
            .map((e) => NoteModel.fromJson(Map<String, dynamic>.from(e)))
            .where((n) => !n.isDeleted && n.isArchived)
            .toList();
        deleted = rawTrash
            .map((e) => NoteModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        
        // Final fallback: merge items that might be miscategorized by the server
        final allPossible = [...active, ...archived, ...deleted];
        categorize(allPossible);
      } else {
        final List allData = (rawData['data'] ?? []) as List;
        categorize(
          allData
              .map((e) => NoteModel.fromJson(Map<String, dynamic>.from(e)))
              .toList(),
        );
      }
    }

    return NoteResponse(
      code: _toInt(json['code'] ?? json['Code']),
      message: _toString(json['message'] ?? json['Message']),
      notes: active,
      archive: archived,
      trash: deleted,
    );
  }
}

// --- Internal Safe Parsers ---

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

String _toString(dynamic value) {
  if (value == null) return '';
  return value.toString();
}
