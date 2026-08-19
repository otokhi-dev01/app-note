import 'package:Note/core/error/result.dart';
import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/features/note/data/repositories/local_note_repository.dart';
import 'package:Note/features/note/domain/entities/note.dart';
import 'package:Note/features/note/domain/entities/note_block.dart';
import 'package:Note/features/note/domain/entities/note_bundle.dart';
import 'package:Note/features/note/domain/repositories/note_repository.dart';

/// Sends every call to on-device storage while in guest mode, and to the real
/// backend otherwise — the one seam that lets `NoteDetailController`,
/// `NoteController`, and every note use case stay unaware that guest mode
/// exists at all.
class NoteRepositoryRouter implements NoteRepository {
  final NoteRepository _remote;
  final LocalNoteRepository _local;
  final GuestModeService _guestMode;

  const NoteRepositoryRouter(this._remote, this._local, this._guestMode);

  NoteRepository get _active => _guestMode.isGuestMode.value ? _local : _remote;

  @override
  Future<Result<NoteBundle>> getNotes({int? folderId}) =>
      _active.getNotes(folderId: folderId);

  @override
  Future<Result<Note>> getNoteDetail(int id) => _active.getNoteDetail(id);

  @override
  Future<Result<Note>> saveNote({
    required int folderId,
    required String title,
    int noteId = 0,
    List<NoteBlock>? content,
  }) => _active.saveNote(
    folderId: folderId,
    title: title,
    noteId: noteId,
    content: content,
  );

  @override
  Future<Result<int>> saveNoteMetadata({
    required int folderId,
    required String title,
    int noteId = 0,
  }) => _active.saveNoteMetadata(
    folderId: folderId,
    title: title,
    noteId: noteId,
  );

  @override
  Future<Result<void>> saveNoteContent({
    required int noteId,
    required String title,
    required List<NoteBlock> content,
  }) => _active.saveNoteContent(noteId: noteId, title: title, content: content);

  @override
  Future<Result<void>> updateNoteState(
    int id, {
    bool? isPinned,
    bool? isArchived,
    bool? isLocked,
  }) => _active.updateNoteState(
    id,
    isPinned: isPinned,
    isArchived: isArchived,
    isLocked: isLocked,
  );

  @override
  Future<Result<void>> deleteRestoreNote(int id, bool isDelete) =>
      _active.deleteRestoreNote(id, isDelete);

  @override
  Future<Result<void>> deleteNotePermanently(int id) =>
      _active.deleteNotePermanently(id);

  @override
  Future<Result<void>> emptyTrash() => _active.emptyTrash();

  @override
  Future<Result<AttachmentUpload>> uploadAttachment({
    required int noteId,
    required String filePath,
    required String blockId,
    required int displayOrder,
  }) => _active.uploadAttachment(
    noteId: noteId,
    filePath: filePath,
    blockId: blockId,
    displayOrder: displayOrder,
  );

  @override
  Future<Result<String>> downloadAttachment({
    required String url,
    required String savePath,
  }) => _active.downloadAttachment(url: url, savePath: savePath);
}
