import 'package:Note/core/error/result.dart';
import 'package:Note/core/error/failures.dart';
import 'package:Note/core/usecase/usecase.dart';
import 'package:Note/features/note/domain/entities/note.dart';
import 'package:Note/features/note/domain/entities/note_block.dart';
import 'package:Note/features/note/domain/entities/note_bundle.dart';
import 'package:Note/features/note/domain/repositories/note_repository.dart';

/// One file per feature rather than one per class: these are thin, and keeping
/// them together makes the feature's whole surface readable at a glance.

// ─────────────────────────────────────────────────────────────── reads

class GetNotes extends UseCase<NoteBundle, GetNotesParams> {
  final NoteRepository _repository;

  const GetNotes(this._repository);

  @override
  Future<Result<NoteBundle>> call(GetNotesParams params) =>
      _repository.getNotes(folderId: params.folderId);
}

class GetNotesParams {
  final int? folderId;

  const GetNotesParams({this.folderId});
}

class GetNoteDetail extends UseCase<Note, int> {
  final NoteRepository _repository;

  const GetNoteDetail(this._repository);

  @override
  Future<Result<Note>> call(int noteId) => _repository.getNoteDetail(noteId);
}

/// The trash slice of the same fetch, so trash and notes never disagree.
class GetTrashNotes extends UseCase<List<Note>, NoParams> {
  final NoteRepository _repository;

  const GetTrashNotes(this._repository);

  @override
  Future<Result<List<Note>>> call(NoParams params) async =>
      (await _repository.getNotes()).map((bundle) => bundle.trash);
}

// ─────────────────────────────────────────────────────────────── writes

class SaveNote extends UseCase<Note, SaveNoteParams> {
  final NoteRepository _repository;

  const SaveNote(this._repository);

  @override
  Future<Result<Note>> call(SaveNoteParams params) {
    if (params.folderId <= 0) {
      return Future.value(
        const Err(ValidationFailure('Pick a folder before saving this note.')),
      );
    }
    return _repository.saveNote(
      folderId: params.folderId,
      title: params.title,
      noteId: params.noteId,
      content: params.content,
    );
  }
}

class SaveNoteParams {
  final int folderId;
  final String title;
  final int noteId;
  final List<NoteBlock>? content;

  const SaveNoteParams({
    required this.folderId,
    required this.title,
    this.noteId = 0,
    this.content,
  });
}

class SaveNoteMetadata extends UseCase<int, SaveNoteParams> {
  final NoteRepository _repository;

  const SaveNoteMetadata(this._repository);

  @override
  Future<Result<int>> call(SaveNoteParams params) =>
      _repository.saveNoteMetadata(
        folderId: params.folderId,
        title: params.title,
        noteId: params.noteId,
      );
}

class SaveNoteContent extends UseCase<void, SaveNoteContentParams> {
  final NoteRepository _repository;

  const SaveNoteContent(this._repository);

  @override
  Future<Result<void>> call(SaveNoteContentParams params) =>
      _repository.saveNoteContent(
        noteId: params.noteId,
        title: params.title,
        content: params.content,
      );
}

class SaveNoteContentParams {
  final int noteId;
  final String title;
  final List<NoteBlock> content;

  const SaveNoteContentParams({
    required this.noteId,
    required this.title,
    required this.content,
  });
}

class UpdateNoteState extends UseCase<void, UpdateNoteStateParams> {
  final NoteRepository _repository;

  const UpdateNoteState(this._repository);

  @override
  Future<Result<void>> call(UpdateNoteStateParams params) =>
      _repository.updateNoteState(
        params.noteId,
        isPinned: params.isPinned,
        isArchived: params.isArchived,
        isLocked: params.isLocked,
      );
}

class UpdateNoteStateParams {
  final int noteId;
  final bool? isPinned;
  final bool? isArchived;
  final bool? isLocked;

  const UpdateNoteStateParams({
    required this.noteId,
    this.isPinned,
    this.isArchived,
    this.isLocked,
  });
}

class DeleteRestoreNote extends UseCase<void, DeleteRestoreNoteParams> {
  final NoteRepository _repository;

  const DeleteRestoreNote(this._repository);

  @override
  Future<Result<void>> call(DeleteRestoreNoteParams params) =>
      _repository.deleteRestoreNote(params.noteId, params.isDelete);
}

class DeleteRestoreNoteParams {
  final int noteId;
  final bool isDelete;

  const DeleteRestoreNoteParams({required this.noteId, required this.isDelete});
}

/// Moves notes between folders by re-saving each note's metadata.
///
/// Reports partial success: the caller needs to know how many of the batch
/// actually landed, which a plain `Result<void>` would hide.
class MoveNotesToFolder extends UseCase<MoveOutcome, MoveNotesParams> {
  final NoteRepository _repository;

  const MoveNotesToFolder(this._repository);

  @override
  Future<Result<MoveOutcome>> call(MoveNotesParams params) async {
    var moved = 0;
    AppFailure? lastFailure;

    for (final note in params.notes) {
      final result = await _repository.saveNoteMetadata(
        folderId: params.targetFolderId,
        title: note.title,
        noteId: note.id,
      );
      switch (result) {
        case Ok<int>():
          moved++;
        case Err<int>(:final failure):
          lastFailure = failure;
      }
    }

    if (moved == 0 && lastFailure != null) return Err(lastFailure);
    return Ok(MoveOutcome(moved: moved, total: params.notes.length));
  }
}

class MoveNotesParams {
  final List<Note> notes;
  final int targetFolderId;

  const MoveNotesParams({required this.notes, required this.targetFolderId});
}

class MoveOutcome {
  final int moved;
  final int total;

  const MoveOutcome({required this.moved, required this.total});

  bool get isComplete => moved == total;
}

class UploadAttachment
    extends UseCase<AttachmentUpload, UploadAttachmentParams> {
  final NoteRepository _repository;

  const UploadAttachment(this._repository);

  @override
  Future<Result<AttachmentUpload>> call(UploadAttachmentParams params) =>
      _repository.uploadAttachment(
        noteId: params.noteId,
        filePath: params.filePath,
        blockId: params.blockId,
        displayOrder: params.displayOrder,
      );
}

class UploadAttachmentParams {
  final int noteId;
  final String filePath;
  final String blockId;
  final int displayOrder;

  const UploadAttachmentParams({
    required this.noteId,
    required this.filePath,
    required this.blockId,
    required this.displayOrder,
  });
}

/// Caches a remote attachment on disk so the image editor can open it.
class DownloadAttachment extends UseCase<String, DownloadAttachmentParams> {
  final NoteRepository _repository;

  const DownloadAttachment(this._repository);

  @override
  Future<Result<String>> call(DownloadAttachmentParams params) {
    if (params.url.trim().isEmpty) {
      return Future.value(
        const Err(ValidationFailure('This attachment has no source file.')),
      );
    }
    return _repository.downloadAttachment(
      url: params.url,
      savePath: params.savePath,
    );
  }
}

class DownloadAttachmentParams {
  final String url;
  final String savePath;

  const DownloadAttachmentParams({required this.url, required this.savePath});
}

// ───────────────────────────────────────────────── unsupported by the backend

class DeleteNotePermanently extends UseCase<void, int> {
  final NoteRepository _repository;

  const DeleteNotePermanently(this._repository);

  @override
  Future<Result<void>> call(int noteId) =>
      _repository.deleteNotePermanently(noteId);
}

class EmptyTrash extends UseCase<void, NoParams> {
  final NoteRepository _repository;

  const EmptyTrash(this._repository);

  @override
  Future<Result<void>> call(NoParams params) => _repository.emptyTrash();
}
