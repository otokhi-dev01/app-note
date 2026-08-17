import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;

import 'package:Note/core/error/exceptions.dart';
import 'package:Note/core/network/api_capabilities.dart';
import 'package:Note/core/network/api_client.dart';
import 'package:Note/core/network/api_error_parser.dart';
import 'package:Note/core/utils/json_parsers.dart';
import 'package:Note/features/note/data/models/note_block_mapper.dart';
import 'package:Note/features/note/data/models/note_model.dart';
import 'package:Note/features/note/data/models/note_response.dart';
import 'package:Note/features/note/domain/entities/note_block.dart';

/// Raw `/api/note` transport.
///
/// Only shapes requests and parses responses; it throws the exceptions in
/// `core/error/exceptions.dart` and lets `NoteRepositoryImpl` decide what they
/// mean. Request/response logging is handled once by the [ApiClient]
/// interceptor, so there is no per-method try/print/rethrow here.
class NoteRemoteDataSource extends GetxService {
  final ApiClient _api = Get.find<ApiClient>();

  Future<NoteResponse> getNotes({int? folderId}) async {
    try {
      final response = await _api.dio.get(
        '/api/note',
        queryParameters: {
          if (folderId != null && folderId != 0) 'folderId': folderId,
        },
      );
      final body = response.data;
      if (body is! Map) return const NoteResponse.empty();
      return NoteResponse.fromJson(Map<String, dynamic>.from(body));
    } on dio.DioException catch (e) {
      throw ApiErrorParser.toException(e);
    }
  }

  Future<NoteModel> getNoteDetail(int id) async {
    try {
      final response = await _api.dio.get('/api/note/$id');

      final body = response.data;
      if (body is! Map) {
        throw const ServerException('Invalid note detail response.');
      }

      final dynamic rawData = body['data'] ?? body['Data'];
      final dynamic rawNote = switch (rawData) {
        List l when l.isNotEmpty => l.first,
        List _ => throw const ServerException(
          'Note detail data list is empty.',
        ),
        Map m => m,
        _ => throw ServerException(
          'Unexpected note detail data type: ${rawData.runtimeType}',
        ),
      };

      if (rawNote is! Map) {
        throw const ServerException('Invalid note object format.');
      }

      return NoteModel.fromJson(Map<String, dynamic>.from(rawNote));
    } on dio.DioException catch (e) {
      throw ApiErrorParser.toException(e);
    }
  }

  /// Saves metadata (title, folder) and returns the created/updated note id.
  ///
  /// Matches `NoteSaveRequest`: `{ noteId, folderId*, title }`.
  Future<int> saveNoteMetadata({
    required int folderId,
    required String title,
    int noteId = 0,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        'folderId': folderId,
        'title': title,
      };
      if (noteId > 0) payload['noteId'] = noteId;

      final response = await _api.dio.post('/api/note/save', data: payload);
      final data = response.data;

      if (data is Map) {
        final extractedId = asInt(
          data['data']?['NoteId'] ??
              data['data']?['id'] ??
              data['NoteId'] ??
              data['id'],
        );
        if (extractedId > 0) return extractedId;
      }

      if (noteId > 0) return noteId;

      // Workaround: on create the backend sometimes answers with a null body,
      // so recover the id by re-reading the folder and taking the newest note.
      if (kDebugMode) {
        debugPrint('[NOTE CREATE] null data — resolving NoteId from list');
      }
      final list = await getNotes(folderId: folderId);
      if (list.notes.isNotEmpty) {
        final sorted = List<NoteModel>.from(list.notes)
          ..sort((a, b) => b.id.compareTo(a.id));
        return sorted.first.id;
      }

      throw const ServerException('Failed to resolve NoteId after save.');
    } on dio.DioException catch (e) {
      throw ApiErrorParser.toException(e);
    }
  }

  /// Saves the structured content blocks for an existing note.
  Future<void> saveNoteContent({
    required int noteId,
    required String title,
    required List<NoteBlock> content,
  }) async {
    try {
      await _api.dio.post(
        '/api/note/save-content',
        data: {
          'id': noteId,
          'title': title,
          'content': content.map(NoteBlockMapper.toJson).toList(),
        },
      );
    } on dio.DioException catch (e) {
      throw ApiErrorParser.toException(e);
    }
  }

  Future<Map<String, dynamic>> uploadAttachment(
    int noteId,
    String filePath,
    String blockId,
    int displayOrder,
  ) async {
    try {
      final formData = dio.FormData.fromMap({
        'Id': noteId.toString(),
        'File': await dio.MultipartFile.fromFile(filePath),
        'BlockId': blockId,
        'DisplayOrder': displayOrder.toString(),
      });

      final response = await _api.dio.post(
        '/api/note/attachment',
        data: formData,
      );

      final body = response.data;
      if (body is! Map) throw const ServerException('Invalid upload response.');

      final outerData = body['data'];
      if (outerData is! Map) {
        throw const ServerException('Invalid upload response data.');
      }

      // Preferred shape: data.data is a list of created records.
      final records = outerData['data'];
      if (records is List && records.isNotEmpty) {
        final record = Map<String, dynamic>.from(records.first as Map);
        return {
          'AttachmentId': asInt(
            record['AttachmentId'] ?? record['attachmentId'] ?? record['id'],
          ),
          'FilePath': asString(
            record['FilePath'] ?? record['filePath'] ?? record['url'],
          ),
          'BlockId': blockId,
        };
      }

      // Fallback shape: the record is inlined on data or the root.
      return {
        'AttachmentId': asInt(
          outerData['AttachmentId'] ?? body['AttachmentId'],
        ),
        'FilePath': asString(outerData['FilePath'] ?? body['FilePath']),
        'BlockId': blockId,
      };
    } on dio.DioException catch (e) {
      throw ApiErrorParser.toException(e);
    }
  }

  /// Pulls a remote attachment down to [savePath] so the image editor, which
  /// only works on local files, has something to open.
  Future<String> downloadAttachment(String url, String savePath) async {
    try {
      await _api.dio.download(url, savePath);
      return savePath;
    } on dio.DioException catch (e) {
      throw ApiErrorParser.toException(e);
    }
  }

  /// `NoteUpdateStateRequest`: `{ id, isPinned?, isArchived?, isLocked? }`.
  /// The DTO has no isDelete field — use [deleteRestoreNote] for that.
  Future<void> updateNoteState(
    int id, {
    bool? isPinned,
    bool? isArchived,
    bool? isLocked,
  }) async {
    try {
      final Map<String, dynamic> payload = {'id': id};
      if (isPinned != null) payload['isPinned'] = isPinned;
      if (isArchived != null) payload['isArchived'] = isArchived;
      if (isLocked != null) payload['isLocked'] = isLocked;

      await _api.dio.post('/api/note/update-state', data: payload);
    } on dio.DioException catch (e) {
      throw ApiErrorParser.toException(e);
    }
  }

  /// Soft-deletes or restores a note.
  /// Matches `NoteDeleteOrRestoreRequest`: `{ id, isDelete }`.
  Future<void> deleteRestoreNote(int id, bool isDelete) async {
    try {
      await _api.dio.post(
        '/api/note/delete-restore',
        data: {'id': id, 'isDelete': isDelete},
      );
    } on dio.DioException catch (e) {
      throw ApiErrorParser.toException(e);
    }
  }

  /// Not supported: no `/api/note/permanent-delete` route exists.
  /// See [ApiCapabilities.permanentDelete].
  Future<void> deleteNotePermanently(int id) async {
    throw const UnsupportedFeatureException(
      'Permanently deleting a note is not available on the server yet.',
    );
  }

  /// Not supported: no `/api/note/empty-trash` route exists.
  /// See [ApiCapabilities.permanentDelete].
  Future<void> emptyTrash() async {
    throw const UnsupportedFeatureException(
      'Emptying the trash is not available on the server yet.',
    );
  }
}
