import 'package:Note/core/error/result.dart';
import 'package:Note/features/note/domain/entities/note.dart';
import 'package:Note/features/note/domain/entities/note_block.dart';
import 'package:Note/features/note/domain/entities/note_bundle.dart';

/// What the app can do with notes, stated without reference to HTTP.
///
/// The implementation lives in `data/repositories/note_repository_impl.dart`.
abstract class NoteRepository {
  /// Active, archived and trashed notes in one call. Pass [folderId] to scope
  /// the active list to a folder.
  Future<Result<NoteBundle>> getNotes({int? folderId});

  Future<Result<Note>> getNoteDetail(int id);

  /// Create or update a note end to end: metadata, then content, then re-read
  /// the saved note so the caller gets server-assigned ids.
  Future<Result<Note>> saveNote({
    required int folderId,
    required String title,
    int noteId = 0,
    List<NoteBlock>? content,
  });

  /// Save title/folder only, returning the created or updated note id.
  Future<Result<int>> saveNoteMetadata({
    required int folderId,
    required String title,
    int noteId = 0,
  });

  Future<Result<void>> saveNoteContent({
    required int noteId,
    required String title,
    required List<NoteBlock> content,
  });

  Future<Result<void>> updateNoteState(
    int id, {
    bool? isPinned,
    bool? isArchived,
    bool? isLocked,
  });

  Future<Result<void>> deleteRestoreNote(int id, bool isDelete);

  /// Unsupported by the current backend — always fails with
  /// [UnsupportedFeatureFailure]. Kept so the UI can show why.
  Future<Result<void>> deleteNotePermanently(int id);

  /// Unsupported by the current backend. See [deleteNotePermanently].
  Future<Result<void>> emptyTrash();

  Future<Result<AttachmentUpload>> uploadAttachment({
    required int noteId,
    required String filePath,
    required String blockId,
    required int displayOrder,
  });

  /// Caches a remote attachment locally and resolves to its file path.
  Future<Result<String>> downloadAttachment({
    required String url,
    required String savePath,
  });
}

/// What the server assigns to a freshly uploaded file.
class AttachmentUpload {
  final int attachmentId;
  final String filePath;
  final String blockId;

  const AttachmentUpload({
    required this.attachmentId,
    required this.filePath,
    required this.blockId,
  });
}
