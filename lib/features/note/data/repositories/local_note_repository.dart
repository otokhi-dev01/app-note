import 'dart:io';

import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';

import 'package:Note/core/error/failures.dart';
import 'package:Note/core/error/result.dart';
import 'package:Note/features/folder/data/repositories/local_folder_repository.dart';
import 'package:Note/features/note/data/models/note_block_mapper.dart';
import 'package:Note/features/note/domain/entities/note.dart';
import 'package:Note/features/note/domain/entities/note_block.dart';
import 'package:Note/features/note/domain/entities/note_bundle.dart';
import 'package:Note/features/note/domain/repositories/note_repository.dart';

/// On-device storage for guest-mode notes — no network, no account.
///
/// Only ever exercised while `GuestModeService.isGuestMode` is true, via
/// `NoteRepositoryRouter`. Attachments have no server to live on, so
/// [uploadAttachment] copies the picked file into permanent app storage and
/// hands back a real local path instead of a URL.
class LocalNoteRepository implements NoteRepository {
  static const _notesKey = 'guest_notes';
  static const _nextNoteIdKey = 'guest_next_note_id';
  static const _nextAttachmentIdKey = 'guest_next_attachment_id';

  final LocalFolderRepository _folders;
  final _storage = GetStorage();

  LocalNoteRepository(this._folders);

  @override
  Future<Result<NoteBundle>> getNotes({int? folderId}) async {
    final all = _readAll();
    final active = all
        .where((n) => !n.isDeleted && !n.isArchived)
        .where((n) => folderId == null || n.folderId == folderId)
        .toList();
    return Ok(
      NoteBundle(
        notes: active,
        archive: all.where((n) => !n.isDeleted && n.isArchived).toList(),
        trash: all.where((n) => n.isDeleted).toList(),
      ),
    );
  }

  @override
  Future<Result<Note>> getNoteDetail(int id) async {
    final match = _readAll().where((n) => n.id == id).firstOrNull;
    if (match == null) return const Err(ServerFailure('Note not found.'));
    return Ok(match);
  }

  @override
  Future<Result<Note>> saveNote({
    required int folderId,
    required String title,
    int noteId = 0,
    List<NoteBlock>? content,
  }) async {
    final idResult = await saveNoteMetadata(
      folderId: folderId,
      title: title,
      noteId: noteId,
    );
    if (idResult case Err(:final failure)) return Err(failure);
    final confirmedId = idResult.valueOrNull!;

    if (content != null && content.isNotEmpty) {
      final contentResult = await saveNoteContent(
        noteId: confirmedId,
        title: title,
        content: content,
      );
      if (contentResult case Err(:final failure)) return Err(failure);
    }

    return getNoteDetail(confirmedId);
  }

  @override
  Future<Result<int>> saveNoteMetadata({
    required int folderId,
    required String title,
    int noteId = 0,
  }) async {
    final all = _readAll();
    final now = DateTime.now();

    if (noteId == 0) {
      final note = Note(
        id: _nextNoteId(),
        folderId: folderId,
        folderName: _folders.folderNameOf(folderId),
        title: title,
        updatedAt: now,
      );
      all.add(note);
      await _writeAll(all);
      return Ok(note.id);
    }

    final index = all.indexWhere((n) => n.id == noteId);
    if (index == -1) return const Err(ServerFailure('Note not found.'));

    final existing = all[index];
    all[index] = Note(
      id: existing.id,
      folderId: folderId,
      folderName: _folders.folderNameOf(folderId),
      title: title,
      content: existing.content,
      isPinned: existing.isPinned,
      isArchived: existing.isArchived,
      isLocked: existing.isLocked,
      updatedAt: now,
      deletedAt: existing.deletedAt,
      attachmentCount: existing.attachmentCount,
    );
    await _writeAll(all);
    return Ok(noteId);
  }

  @override
  Future<Result<void>> saveNoteContent({
    required int noteId,
    required String title,
    required List<NoteBlock> content,
  }) async {
    final all = _readAll();
    final index = all.indexWhere((n) => n.id == noteId);
    if (index == -1) return const Err(ServerFailure('Note not found.'));

    final existing = all[index];
    all[index] = Note(
      id: existing.id,
      folderId: existing.folderId,
      folderName: existing.folderName,
      title: title,
      content: content,
      isPinned: existing.isPinned,
      isArchived: existing.isArchived,
      isLocked: existing.isLocked,
      updatedAt: DateTime.now(),
      deletedAt: existing.deletedAt,
      attachmentCount: content.whereType<AttachmentBlock>().length,
    );
    await _writeAll(all);
    return okVoid;
  }

  @override
  Future<Result<void>> updateNoteState(
    int id, {
    bool? isPinned,
    bool? isArchived,
    bool? isLocked,
  }) async {
    final all = _readAll();
    final index = all.indexWhere((n) => n.id == id);
    if (index == -1) return const Err(ServerFailure('Note not found.'));

    final existing = all[index];
    all[index] = Note(
      id: existing.id,
      folderId: existing.folderId,
      folderName: existing.folderName,
      title: existing.title,
      content: existing.content,
      isPinned: isPinned ?? existing.isPinned,
      isArchived: isArchived ?? existing.isArchived,
      isLocked: isLocked ?? existing.isLocked,
      updatedAt: DateTime.now(),
      deletedAt: existing.deletedAt,
      attachmentCount: existing.attachmentCount,
    );
    await _writeAll(all);
    return okVoid;
  }

  @override
  Future<Result<void>> deleteRestoreNote(int id, bool isDelete) async {
    final all = _readAll();
    final index = all.indexWhere((n) => n.id == id);
    if (index == -1) return const Err(ServerFailure('Note not found.'));

    final existing = all[index];
    all[index] = Note(
      id: existing.id,
      folderId: existing.folderId,
      folderName: existing.folderName,
      title: existing.title,
      content: existing.content,
      isPinned: existing.isPinned,
      isArchived: existing.isArchived,
      isLocked: existing.isLocked,
      updatedAt: DateTime.now(),
      deletedAt: isDelete ? DateTime.now() : null,
      attachmentCount: existing.attachmentCount,
    );
    await _writeAll(all);
    return okVoid;
  }

  /// Unlike the real backend, guest data is entirely local — a permanent
  /// delete can just remove the row (and its files).
  @override
  Future<Result<void>> deleteNotePermanently(int id) async {
    final all = _readAll();
    final match = all.where((n) => n.id == id).firstOrNull;
    if (match != null) await _deleteAttachmentFiles(match);
    all.removeWhere((n) => n.id == id);
    await _writeAll(all);
    return okVoid;
  }

  @override
  Future<Result<void>> emptyTrash() async {
    final all = _readAll();
    for (final note in all.where((n) => n.isDeleted)) {
      await _deleteAttachmentFiles(note);
    }
    all.removeWhere((n) => n.isDeleted);
    await _writeAll(all);
    return okVoid;
  }

  /// Copies the picked file into permanent app storage — there is no server
  /// to upload it to, so the "upload" is really just making the file outlive
  /// whatever temporary/cache directory the picker put it in.
  @override
  Future<Result<AttachmentUpload>> uploadAttachment({
    required int noteId,
    required String filePath,
    required String blockId,
    required int displayOrder,
  }) async {
    final source = File(filePath);
    if (!source.existsSync()) {
      return const Err(ValidationFailure('That file could not be found.'));
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final attachmentsDir = Directory('${dir.path}/guest_attachments');
      if (!attachmentsDir.existsSync()) {
        await attachmentsDir.create(recursive: true);
      }

      final id = _nextAttachmentId();
      final dot = filePath.lastIndexOf('.');
      final slash = filePath.lastIndexOf('/');
      final extension = (dot > slash) ? filePath.substring(dot) : '';
      final destPath = '${attachmentsDir.path}/$id$extension';
      final copied = await source.copy(destPath);

      return Ok(
        AttachmentUpload(
          attachmentId: id,
          filePath: copied.path,
          blockId: blockId,
          isLocal: true,
        ),
      );
    } catch (_) {
      return const Err(UnknownFailure('Could not save that attachment.'));
    }
  }

  /// Guest attachments are always local already — there is nothing to
  /// download from. Only reached if a block somehow lost its local file.
  @override
  Future<Result<String>> downloadAttachment({
    required String url,
    required String savePath,
  }) async {
    final source = File(url);
    if (source.existsSync()) {
      await source.copy(savePath);
      return Ok(savePath);
    }
    return const Err(
      UnsupportedFeatureFailure('This attachment is no longer available.'),
    );
  }

  /// Clears every locally-stored guest note and its attachment files — used
  /// when an account is deleted or when guest data should not carry over to
  /// a signed-in session.
  Future<void> clear() async {
    for (final note in _readAll()) {
      await _deleteAttachmentFiles(note);
    }
    await _storage.remove(_notesKey);
    await _storage.remove(_nextNoteIdKey);
    await _storage.remove(_nextAttachmentIdKey);
  }

  Future<void> _deleteAttachmentFiles(Note note) async {
    for (final block in note.content.whereType<AttachmentBlock>()) {
      final path = block.localPath;
      if (path == null) continue;
      final file = File(path);
      if (file.existsSync()) await file.delete();
    }
  }

  List<Note> _readAll() {
    final raw = _storage.read<List>(_notesKey);
    if (raw == null) return const [];
    return raw
        .whereType<Map>()
        .map((m) => _fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> _writeAll(List<Note> notes) =>
      _storage.write(_notesKey, notes.map(_toJson).toList());

  int _nextNoteId() {
    final next = (_storage.read<int>(_nextNoteIdKey) ?? 0) - 1;
    _storage.write(_nextNoteIdKey, next);
    return next;
  }

  int _nextAttachmentId() {
    final next = (_storage.read<int>(_nextAttachmentIdKey) ?? 0) - 1;
    _storage.write(_nextAttachmentIdKey, next);
    return next;
  }

  static Map<String, dynamic> _toJson(Note n) => {
    'id': n.id,
    'folderId': n.folderId,
    'folderName': n.folderName,
    'title': n.title,
    'content': n.content.map(_blockToJson).toList(),
    'isPinned': n.isPinned,
    'isArchived': n.isArchived,
    'isLocked': n.isLocked,
    'updatedAt': n.updatedAt?.toIso8601String(),
    'deletedAt': n.deletedAt?.toIso8601String(),
    'attachmentCount': n.attachmentCount,
  };

  static Note _fromJson(Map<String, dynamic> j) => Note(
    id: j['id'] as int,
    folderId: j['folderId'] as int? ?? 0,
    folderName: j['folderName'] as String? ?? 'Notes',
    title: j['title'] as String? ?? '',
    content: (j['content'] as List? ?? const [])
        .whereType<Map>()
        .map((m) => _blockFromJson(Map<String, dynamic>.from(m)))
        .toList(),
    isPinned: j['isPinned'] as bool? ?? false,
    isArchived: j['isArchived'] as bool? ?? false,
    isLocked: j['isLocked'] as bool? ?? false,
    updatedAt: _parseDate(j['updatedAt']),
    deletedAt: _parseDate(j['deletedAt']),
    attachmentCount: j['attachmentCount'] as int? ?? 0,
  );

  /// `NoteBlockMapper.toJson` deliberately omits `localPath` — it's the wire
  /// format for a backend that has no concept of "this device's filesystem".
  /// Guest storage is the opposite: `localPath` is the only thing that makes
  /// an attachment block usable again after a restart, so it's added back in.
  static Map<String, dynamic> _blockToJson(NoteBlock block) {
    final json = NoteBlockMapper.toJson(block);
    if (block is AttachmentBlock && block.localPath != null) {
      json['localPath'] = block.localPath;
    }
    return json;
  }

  static NoteBlock _blockFromJson(Map<String, dynamic> json) =>
      NoteBlockMapper.fromJson(json);

  static DateTime? _parseDate(dynamic v) =>
      v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;
}
