import '../entities/note_entity.dart';
import 'note_state_field.dart';

abstract class NoteRepository {
  /// GET /api/note
  Future<List<NoteEntity>> getNotes();

  /// GET /api/note/{id}
  Future<NoteEntity> getNoteDetail(int noteId);

  /// POST /api/note/save
  Future<int> saveNote({
    required int noteId,
    required int folderId,
    required String title,
  });

  /// POST /api/note/save-content with `{id, title, content}`.
  Future<void> saveContent({
    required int id,
    required String title,
    required List<Map<String, dynamic>> content,
  });

  /// POST /api/note/attachment
  Future<void> uploadAttachment({
    required int noteId,
    required String filePath,
    required String blockId,
    required int displayOrder,
  });

  /// POST /api/note/update-state
  Future<void> updateState({
    required int noteId,
    required bool isPinned,
    required bool isArchived,
    required bool isLocked,
    NoteStateField? changedField,
  });
}
