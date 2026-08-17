import 'package:Note/core/error/guard.dart';
import 'package:Note/core/error/result.dart';
import 'package:Note/features/note/data/datasources/note_remote_data_source.dart';
import 'package:Note/features/note/domain/entities/note.dart';
import 'package:Note/features/note/domain/entities/note_block.dart';
import 'package:Note/features/note/domain/entities/note_bundle.dart';
import 'package:Note/features/note/domain/repositories/note_repository.dart';

class NoteRepositoryImpl implements NoteRepository {
  final NoteRemoteDataSource _remote;

  const NoteRepositoryImpl(this._remote);

  @override
  Future<Result<NoteBundle>> getNotes({int? folderId}) => guard(() async {
    final response = await _remote.getNotes(folderId: folderId);
    return NoteBundle(
      notes: response.notes,
      archive: response.archive,
      trash: response.trash,
    );
  });

  @override
  Future<Result<Note>> getNoteDetail(int id) =>
      guard(() => _remote.getNoteDetail(id));

  /// The one multi-step operation: the backend needs metadata saved before it
  /// will accept content, and only returns the note id from the first call.
  @override
  Future<Result<Note>> saveNote({
    required int folderId,
    required String title,
    int noteId = 0,
    List<NoteBlock>? content,
  }) => guard(() async {
    final confirmedId = await _remote.saveNoteMetadata(
      folderId: folderId,
      title: title,
      noteId: noteId,
    );

    if (content != null && content.isNotEmpty) {
      await _remote.saveNoteContent(
        noteId: confirmedId,
        title: title,
        content: content,
      );
    }

    return await _remote.getNoteDetail(confirmedId);
  });

  @override
  Future<Result<int>> saveNoteMetadata({
    required int folderId,
    required String title,
    int noteId = 0,
  }) => guard(
    () => _remote.saveNoteMetadata(
      folderId: folderId,
      title: title,
      noteId: noteId,
    ),
  );

  @override
  Future<Result<void>> saveNoteContent({
    required int noteId,
    required String title,
    required List<NoteBlock> content,
  }) => guard(
    () =>
        _remote.saveNoteContent(noteId: noteId, title: title, content: content),
  );

  @override
  Future<Result<void>> updateNoteState(
    int id, {
    bool? isPinned,
    bool? isArchived,
    bool? isLocked,
  }) => guard(
    () => _remote.updateNoteState(
      id,
      isPinned: isPinned,
      isArchived: isArchived,
      isLocked: isLocked,
    ),
  );

  @override
  Future<Result<void>> deleteRestoreNote(int id, bool isDelete) =>
      guard(() => _remote.deleteRestoreNote(id, isDelete));

  @override
  Future<Result<void>> deleteNotePermanently(int id) =>
      guard(() => _remote.deleteNotePermanently(id));

  @override
  Future<Result<void>> emptyTrash() => guard(() => _remote.emptyTrash());

  @override
  Future<Result<AttachmentUpload>> uploadAttachment({
    required int noteId,
    required String filePath,
    required String blockId,
    required int displayOrder,
  }) => guard(() async {
    final raw = await _remote.uploadAttachment(
      noteId,
      filePath,
      blockId,
      displayOrder,
    );
    return AttachmentUpload(
      attachmentId: raw['AttachmentId'] as int,
      filePath: raw['FilePath'] as String,
      blockId: raw['BlockId'] as String,
    );
  });

  @override
  Future<Result<String>> downloadAttachment({
    required String url,
    required String savePath,
  }) => guard(() => _remote.downloadAttachment(url, savePath));
}
