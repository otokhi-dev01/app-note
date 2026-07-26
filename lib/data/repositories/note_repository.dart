import 'package:dio/dio.dart' as dio;
import '../models/note_model.dart';
import '../providers/api_provider.dart';

class NoteRepository extends ApiProvider {
  Future<Map<String, List<NoteModel>>> getAllNotes() async {
    final response = await get('/note');
    if (response.statusCode == 200) {
      final data = response.data['data'];
      if (data is Map) {
        return {
          'note': (data['note'] as List?)?.map((e) => NoteModel.fromJson(e)).toList() ?? [],
          'archive': (data['archive'] as List?)?.map((e) => NoteModel.fromJson(e)).toList() ?? [],
          'trash': (data['trash'] as List?)?.map((e) => NoteModel.fromJson(e)).toList() ?? [],
        };
      }
    }
    return {'note': [], 'archive': [], 'trash': []};
  }

  Future<NoteModel?> getNoteDetail(int id) async {
    final response = await get('/note/$id');
    if (response.statusCode == 200) {
      final List data = response.data['data'];
      if (data.isNotEmpty) {
        return NoteModel.fromJson(data[0]);
      }
    }
    return null;
  }

  Future<int?> saveNote(int noteId, int folderId, String title) async {
    final response = await post('/note/save', data: {
      'noteId': noteId,
      'folderId': folderId,
      'title': title,
    });
    if (response.statusCode == 200) {
      return response.data['data']?['noteId'];
    }
    return null;
  }

  Future<dio.Response> saveContent(int id, String title, List content) async {
    return await post('/note/save-content', data: {
      'id': id,
      'title': title,
      'content': content,
    });
  }

  Future<dio.Response> updateNoteState({
    required int id,
    bool? isPinned,
    bool? isArchived,
    bool? isLocked,
  }) async {
    return await post('/note/update-state', data: {
      'id': id,
      'isPinned': ?isPinned,
      'isArchived': ?isArchived,
      'isLocked': ?isLocked,
    });
  }

  Future<dio.Response> deleteRestoreNote(int id, bool isDelete) async {
    return await post('/note/delete-restore', data: {
      'id': id,
      'isDelete': isDelete,
    });
  }

  Future<dio.Response> clearTrash() async {
    return await post('/note/clear-trash');
  }

  Future<dio.Response> uploadAttachment({
    required int noteId,
    required String filePath,
    required String blockId,
    int displayOrder = 1,
  }) async {
    String fileName = filePath.split('/').last;
    dio.FormData formData = dio.FormData.fromMap({
      'Id': noteId.toString(),
      'BlockId': blockId,
      'DisplayOrder': displayOrder.toString(),
      'File': await dio.MultipartFile.fromFile(filePath, filename: fileName),
    });

    return await post('/note/attachment', data: formData);
  }
}
