import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';

import 'package:Note/core/error/failures.dart';
import 'package:Note/core/error/result.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/features/folder/data/repositories/folder_sync_repository.dart';
import 'package:Note/features/note/data/models/note_block_mapper.dart';
import 'package:Note/features/note/domain/entities/note.dart';
import 'package:Note/features/note/domain/entities/note_block.dart';
import 'package:Note/features/note/domain/entities/note_bundle.dart';
import 'package:Note/features/note/domain/repositories/note_repository.dart';

/// Lets a signed-in account keep using notes while offline.
///
/// Mirrors `FolderSyncRepository`: reads are served from a cache kept in
/// sync with the server whenever it's reachable, writes apply to that cache
/// immediately and queue for replay, and a [NetworkFailure] is the only
/// failure treated as "offline" — everything else (auth, validation, the
/// backend's permanent-delete/empty-trash being unsupported) passes through
/// unchanged.
///
/// Takes the account's [FolderSyncRepository] the same way `LocalNoteRepository`
/// takes `LocalFolderRepository`: to look up a folder's display name for the
/// cache, and — since a note can be created inside a folder that was itself
/// created offline — to resolve that folder's temp id to its real one once
/// the folder has synced.
///
/// Only used for signed-in accounts, wired in as the "remote" side of
/// `NoteRepositoryRouter` — guest mode has its own always-local, never-synced
/// `LocalNoteRepository`.
class NoteSyncRepository implements NoteRepository {
  final NoteRepository _remote;
  final SessionStorage _session;
  final FolderSyncRepository _folders;
  final _storage = GetStorage();

  NoteSyncRepository(this._remote, this._session, this._folders);

  String get _uid => _session.user.value?.id ?? 'unknown';
  String get _cacheKey => 'account_notes_cache_$_uid';
  String get _queueKey => 'account_notes_queue_$_uid';
  String get _nextIdKey => 'account_notes_next_id_$_uid';
  String get _nextAttachmentIdKey => 'account_notes_next_attachment_id_$_uid';

  /// Writes still waiting to reach the server — exposed so the UI can show a
  /// "syncing…" indicator if it wants one.
  int get pendingCount => _readQueue().length;

  bool _isOfflineOrAuthFailure(AppFailure failure) {
    if (failure is NetworkFailure) return true;
    if (kDebugMode) {
      if (failure is UnauthorizedFailure) return true;
      if (failure is ServerFailure && failure.statusCode == 401) return true;
    }
    return false;
  }

  @override
  Future<Result<NoteBundle>> getNotes({int? folderId}) async {
    await flushPending();

    final result = await _remote.getNotes(folderId: folderId);
    switch (result) {
      case Ok(:final value):
        var list = _readCache();
        for (final n in [...value.notes, ...value.archive, ...value.trash]) {
          list = _upsertNote(list, n);
        }
        if (folderId == null) {
          // A full, unscoped fetch is authoritative for the whole account —
          // drop any already-synced cache entries the server no longer
          // reports. Anything still waiting to sync (a temp id) is never
          // pruned; the server has never heard of it yet.
          final freshIds = {
            for (final n in [...value.notes, ...value.archive, ...value.trash])
              n.id,
          };
          list = list
              .where((n) => n.id < 0 || freshIds.contains(n.id))
              .toList();
        }
        for (final op in _readQueue()) {
          list = _apply(list, op);
        }
        await _writeCache(list);
        return Ok(_bundle(list, folderId));
      case Err(:final failure):
        if (!_isOfflineOrAuthFailure(failure)) return Err(failure);
        return Ok(_bundle(_readCache(), folderId));
    }
  }

  @override
  Future<Result<Note>> getNoteDetail(int id) async {
    if (id < 0) {
      final match = _readCache().where((n) => n.id == id).firstOrNull;
      return match == null
          ? const Err(ServerFailure('Note not found.'))
          : Ok(match);
    }

    final result = await _remote.getNoteDetail(id);
    switch (result) {
      case Ok(:final value):
        await _writeCache(_upsertNote(_readCache(), value));
        return Ok(value);
      case Err(:final failure):
        if (!_isOfflineOrAuthFailure(failure)) return Err(failure);
        final match = _readCache().where((n) => n.id == id).firstOrNull;
        return match == null ? Err(failure) : Ok(match);
    }
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
    if (noteId < 0) {
      await _writeCache(
        _apply(
          _readCache(),
          _NoteOp.metadata(id: noteId, folderId: folderId, title: title),
        ),
      );
      _upsertMetadata(noteId, folderId, title);
      return Ok(noteId);
    }

    final result = await _remote.saveNoteMetadata(
      folderId: folderId,
      title: title,
      noteId: noteId,
    );
    switch (result) {
      case Ok(:final value):
        await _writeCache(
          _apply(
            _readCache(),
            _NoteOp.metadata(id: value, folderId: folderId, title: title),
          ),
        );
        return Ok(value);
      case Err(:final failure):
        if (!_isOfflineOrAuthFailure(failure)) return Err(failure);
        final assignedId = noteId == 0 ? _nextTempId() : noteId;
        await _writeCache(
          _apply(
            _readCache(),
            _NoteOp.metadata(id: assignedId, folderId: folderId, title: title),
          ),
        );
        _upsertMetadata(assignedId, folderId, title);
        return Ok(assignedId);
    }
  }

  @override
  Future<Result<void>> saveNoteContent({
    required int noteId,
    required String title,
    required List<NoteBlock> content,
  }) async {
    if (noteId < 0) {
      await _writeCache(
        _apply(
          _readCache(),
          _NoteOp.content(id: noteId, title: title, content: content),
        ),
      );
      _upsertContent(noteId, title, content);
      return okVoid;
    }

    final result = await _remote.saveNoteContent(
      noteId: noteId,
      title: title,
      content: content,
    );
    switch (result) {
      case Ok():
        await _writeCache(
          _apply(
            _readCache(),
            _NoteOp.content(id: noteId, title: title, content: content),
          ),
        );
        return okVoid;
      case Err(:final failure):
        if (!_isOfflineOrAuthFailure(failure)) return Err(failure);
        await _writeCache(
          _apply(
            _readCache(),
            _NoteOp.content(id: noteId, title: title, content: content),
          ),
        );
        _upsertContent(noteId, title, content);
        return okVoid;
    }
  }

  @override
  Future<Result<void>> updateNoteState(
    int id, {
    bool? isPinned,
    bool? isArchived,
    bool? isLocked,
  }) async {
    if (id < 0) {
      await _writeCache(
        _apply(
          _readCache(),
          _NoteOp.state(
            id: id,
            isPinned: isPinned,
            isArchived: isArchived,
            isLocked: isLocked,
          ),
        ),
      );
      _upsertState(id, isPinned, isArchived, isLocked);
      return okVoid;
    }

    final result = await _remote.updateNoteState(
      id,
      isPinned: isPinned,
      isArchived: isArchived,
      isLocked: isLocked,
    );
    switch (result) {
      case Ok():
        await _writeCache(
          _apply(
            _readCache(),
            _NoteOp.state(
              id: id,
              isPinned: isPinned,
              isArchived: isArchived,
              isLocked: isLocked,
            ),
          ),
        );
        return okVoid;
      case Err(:final failure):
        if (!_isOfflineOrAuthFailure(failure)) return Err(failure);
        await _writeCache(
          _apply(
            _readCache(),
            _NoteOp.state(
              id: id,
              isPinned: isPinned,
              isArchived: isArchived,
              isLocked: isLocked,
            ),
          ),
        );
        _upsertState(id, isPinned, isArchived, isLocked);
        return okVoid;
    }
  }

  @override
  Future<Result<void>> deleteRestoreNote(int id, bool isDelete) async {
    if (id < 0) {
      await _writeCache(
        _apply(_readCache(), _NoteOp.deleteRestore(id: id, isDelete: isDelete)),
      );
      _upsertDeleteRestore(id, isDelete);
      return okVoid;
    }

    final result = await _remote.deleteRestoreNote(id, isDelete);
    switch (result) {
      case Ok():
        await _writeCache(
          _apply(
            _readCache(),
            _NoteOp.deleteRestore(id: id, isDelete: isDelete),
          ),
        );
        return okVoid;
      case Err(:final failure):
        if (!_isOfflineOrAuthFailure(failure)) return Err(failure);
        await _writeCache(
          _apply(
            _readCache(),
            _NoteOp.deleteRestore(id: id, isDelete: isDelete),
          ),
        );
        _upsertDeleteRestore(id, isDelete);
        return okVoid;
    }
  }

  /// Unlike the real backend, an offline-only note (never synced) is only
  /// ever known to this device — a permanent delete can just remove it.
  @override
  Future<Result<void>> deleteNotePermanently(int id) async {
    if (id < 0) {
      final match = _readCache().where((n) => n.id == id).firstOrNull;
      if (match != null) await _deleteAttachmentFiles(match);
      await _writeCache(_readCache()..removeWhere((n) => n.id == id));
      await _writeQueue(_readQueue()..removeWhere((op) => op.id == id));
      return okVoid;
    }
    return _remote.deleteNotePermanently(id);
  }

  @override
  Future<Result<void>> emptyTrash() async {
    final all = _readCache();
    final localOnly = all.where((n) => n.isDeleted && n.id < 0).toList();
    if (localOnly.isNotEmpty) {
      for (final n in localOnly) {
        await _deleteAttachmentFiles(n);
      }
      final ids = localOnly.map((n) => n.id).toSet();
      await _writeCache(all.where((n) => !ids.contains(n.id)).toList());
      await _writeQueue(_readQueue()..removeWhere((op) => ids.contains(op.id)));
    }
    // Real, already-synced trashed notes still go through the backend,
    // which — same as before this feature existed — always answers
    // "unsupported" for this endpoint.
    return _remote.emptyTrash();
  }

  /// Copies the picked file into permanent app storage and queues the actual
  /// upload for the next time the server is reachable — there is no way to
  /// hand the server a file while offline, but the block can still show the
  /// image/attachment locally in the meantime.
  @override
  Future<Result<AttachmentUpload>> uploadAttachment({
    required int noteId,
    required String filePath,
    required String blockId,
    required int displayOrder,
  }) async {
    if (noteId < 0) {
      return _storeAttachmentLocallyAndQueue(
        noteId: noteId,
        filePath: filePath,
        blockId: blockId,
        displayOrder: displayOrder,
      );
    }

    final result = await _remote.uploadAttachment(
      noteId: noteId,
      filePath: filePath,
      blockId: blockId,
      displayOrder: displayOrder,
    );
    switch (result) {
      case Ok(:final value):
        return Ok(value);
      case Err(:final failure):
        if (!_isOfflineOrAuthFailure(failure)) return Err(failure);
        return _storeAttachmentLocallyAndQueue(
          noteId: noteId,
          filePath: filePath,
          blockId: blockId,
          displayOrder: displayOrder,
        );
    }
  }

  @override
  Future<Result<String>> downloadAttachment({
    required String url,
    required String savePath,
  }) async {
    final result = await _remote.downloadAttachment(
      url: url,
      savePath: savePath,
    );
    switch (result) {
      case Ok(:final value):
        return Ok(value);
      case Err(:final failure):
        if (!_isOfflineOrAuthFailure(failure)) return Err(failure);
        // `url` may already be a local path — an attachment created offline,
        // or one downloaded earlier — in which case there is nothing to
        // fetch from the network at all.
        final source = File(url);
        if (source.existsSync()) {
          await source.copy(savePath);
          return Ok(savePath);
        }
        return Err(failure);
    }
  }

  /// Replays queued writes against the server, in the order they were made.
  /// Folders flush first so a note's `folderId` can be resolved to a real
  /// id before the note itself is sent.
  ///
  /// Stops at the first [NetworkFailure] — still offline — leaving that op
  /// and everything behind it queued. Any other failure drops just that one
  /// op, the same reasoning as `FolderSyncRepository.flushPending`.
  Future<void> flushPending() async {
    await _folders.flushPending();

    final queue = _readQueue();
    if (queue.isEmpty) return;

    final tempToReal = <int, int>{};
    final stillQueued = <_NoteOp>[];
    var offline = false;
    var list = _readCache();
    var listChanged = false;

    for (final op in queue) {
      final remapped = _remapOp(op, tempToReal);
      if (offline) {
        stillQueued.add(remapped);
        continue;
      }

      switch (remapped.type) {
        case _NoteOpType.metadata:
          final folderId = _folders.resolveId(remapped.folderId!);
          final result = await _remote.saveNoteMetadata(
            folderId: folderId,
            title: remapped.title!,
            noteId: remapped.id < 0 ? 0 : remapped.id,
          );
          switch (result) {
            case Ok(:final value):
              if (remapped.id < 0) tempToReal[remapped.id] = value;
              list = _apply(
                list,
                _NoteOp.metadata(
                  id: value,
                  folderId: folderId,
                  title: remapped.title!,
                ),
              );
              listChanged = true;
            case Err(:final failure):
              if (_isOfflineOrAuthFailure(failure)) {
                offline = true;
                stillQueued.add(remapped);
              }
          }
        case _NoteOpType.content:
          final result = await _remote.saveNoteContent(
            noteId: remapped.id,
            title: remapped.title ?? '',
            content: remapped.content!,
          );
          if (result
              case Err(:final failure)
              when _isOfflineOrAuthFailure(failure)) {
            offline = true;
            stillQueued.add(remapped);
          }
        case _NoteOpType.state:
          final result = await _remote.updateNoteState(
            remapped.id,
            isPinned: remapped.isPinned,
            isArchived: remapped.isArchived,
            isLocked: remapped.isLocked,
          );
          if (result
              case Err(:final failure)
              when _isOfflineOrAuthFailure(failure)) {
            offline = true;
            stillQueued.add(remapped);
          }
        case _NoteOpType.deleteRestore:
          final result = await _remote.deleteRestoreNote(
            remapped.id,
            remapped.isDelete!,
          );
          if (result
              case Err(:final failure)
              when _isOfflineOrAuthFailure(failure)) {
            offline = true;
            stillQueued.add(remapped);
          }
        case _NoteOpType.attachment:
          final result = await _remote.uploadAttachment(
            noteId: remapped.id,
            filePath: remapped.filePath!,
            blockId: remapped.blockId!,
            displayOrder: remapped.displayOrder ?? 0,
          );
          switch (result) {
            case Ok(:final value):
              list = _patchAttachment(
                list,
                remapped.id,
                remapped.blockId!,
                value,
              );
              listChanged = true;
            case Err(:final failure):
              if (_isOfflineOrAuthFailure(failure)) {
                offline = true;
                stillQueued.add(remapped);
              }
          }
      }
    }

    await _writeQueue(stillQueued);
    if (tempToReal.isNotEmpty) {
      list = list.map((n) => _remapNote(n, tempToReal)).toList();
      listChanged = true;
    }
    if (listChanged) await _writeCache(list);
  }

  // ── cache/queue mutation helpers ─────────────────────────────────────

  List<Note> _apply(List<Note> list, _NoteOp op) {
    final now = DateTime.now();
    final idx = list.indexWhere((n) => n.id == op.id);

    switch (op.type) {
      case _NoteOpType.metadata:
        final folderName = _folders.folderNameOf(op.folderId!);
        if (idx == -1) {
          return [
            ...list,
            Note(
              id: op.id,
              folderId: op.folderId!,
              folderName: folderName,
              title: op.title!,
              updatedAt: now,
            ),
          ];
        }
        final existing = list[idx];
        final updated = Note(
          id: existing.id,
          folderId: op.folderId!,
          folderName: folderName,
          title: op.title!,
          content: existing.content,
          isPinned: existing.isPinned,
          isArchived: existing.isArchived,
          isLocked: existing.isLocked,
          updatedAt: now,
          deletedAt: existing.deletedAt,
          attachmentCount: existing.attachmentCount,
        );
        return [
          for (final n in list)
            if (n.id == op.id) updated else n,
        ];
      case _NoteOpType.content:
        if (idx == -1) return list;
        final existing = list[idx];
        final blocks = op.content!;
        final updated = Note(
          id: existing.id,
          folderId: existing.folderId,
          folderName: existing.folderName,
          title: op.title ?? existing.title,
          content: blocks,
          isPinned: existing.isPinned,
          isArchived: existing.isArchived,
          isLocked: existing.isLocked,
          updatedAt: now,
          deletedAt: existing.deletedAt,
          attachmentCount: blocks.whereType<AttachmentBlock>().length,
        );
        return [
          for (final n in list)
            if (n.id == op.id) updated else n,
        ];
      case _NoteOpType.state:
        if (idx == -1) return list;
        final existing = list[idx];
        final updated = Note(
          id: existing.id,
          folderId: existing.folderId,
          folderName: existing.folderName,
          title: existing.title,
          content: existing.content,
          isPinned: op.isPinned ?? existing.isPinned,
          isArchived: op.isArchived ?? existing.isArchived,
          isLocked: op.isLocked ?? existing.isLocked,
          updatedAt: now,
          deletedAt: existing.deletedAt,
          attachmentCount: existing.attachmentCount,
        );
        return [
          for (final n in list)
            if (n.id == op.id) updated else n,
        ];
      case _NoteOpType.deleteRestore:
        if (idx == -1) return list;
        final existing = list[idx];
        final updated = Note(
          id: existing.id,
          folderId: existing.folderId,
          folderName: existing.folderName,
          title: existing.title,
          content: existing.content,
          isPinned: existing.isPinned,
          isArchived: existing.isArchived,
          isLocked: existing.isLocked,
          updatedAt: now,
          deletedAt: op.isDelete! ? now : null,
          attachmentCount: existing.attachmentCount,
        );
        return [
          for (final n in list)
            if (n.id == op.id) updated else n,
        ];
      case _NoteOpType.attachment:
        // Only ever patched directly during flushPending — see
        // _patchAttachment.
        return list;
    }
  }

  List<Note> _patchAttachment(
    List<Note> list,
    int noteId,
    String blockId,
    AttachmentUpload upload,
  ) {
    final idx = list.indexWhere((n) => n.id == noteId);
    if (idx == -1) return list;
    final existing = list[idx];
    final newContent = [
      for (final b in existing.content)
        if (b is AttachmentBlock && b.id == blockId)
          AttachmentBlock(
            id: b.id,
            attachmentId: upload.attachmentId,
            displayName: b.displayName,
            url: upload.isLocal ? b.url : upload.filePath,
            localPath: b.localPath,
          )
        else
          b,
    ];
    final updated = Note(
      id: existing.id,
      folderId: existing.folderId,
      folderName: existing.folderName,
      title: existing.title,
      content: newContent,
      isPinned: existing.isPinned,
      isArchived: existing.isArchived,
      isLocked: existing.isLocked,
      updatedAt: existing.updatedAt,
      deletedAt: existing.deletedAt,
      attachmentCount: existing.attachmentCount,
    );
    return [
      for (final n in list)
        if (n.id == noteId) updated else n,
    ];
  }

  List<Note> _upsertNote(List<Note> list, Note note) {
    final idx = list.indexWhere((n) => n.id == note.id);
    if (idx == -1) return [...list, note];

    final existing = list[idx];
    final mergedContent = note.content.map((incomingBlock) {
      if (incomingBlock is AttachmentBlock) {
        final matchingExisting = existing.content
            .whereType<AttachmentBlock>()
            .where(
              (b) =>
                  b.id == incomingBlock.id ||
                  (incomingBlock.attachmentId != 0 &&
                      b.attachmentId == incomingBlock.attachmentId),
            )
            .firstOrNull;

        if (matchingExisting != null &&
            (incomingBlock.localPath == null ||
                incomingBlock.localPath!.isEmpty) &&
            matchingExisting.localPath != null &&
            matchingExisting.localPath!.isNotEmpty) {
          return incomingBlock.copyWith(localPath: matchingExisting.localPath);
        }
      } else if (incomingBlock is DrawingBlock) {
        final matchingExisting = existing.content
            .whereType<DrawingBlock>()
            .where((b) => b.id == incomingBlock.id)
            .firstOrNull;

        if (matchingExisting != null &&
            (incomingBlock.localPath == null ||
                incomingBlock.localPath!.isEmpty) &&
            matchingExisting.localPath != null &&
            matchingExisting.localPath!.isNotEmpty) {
          return incomingBlock.copyWith(localPath: matchingExisting.localPath);
        }
      }
      return incomingBlock;
    }).toList();

    final mergedNote = Note(
      id: note.id,
      folderId: note.folderId,
      folderName: note.folderName,
      title: note.title,
      content: mergedContent,
      isPinned: note.isPinned,
      isArchived: note.isArchived,
      isLocked: note.isLocked,
      updatedAt: note.updatedAt,
      deletedAt: note.deletedAt,
      attachmentCount: note.attachmentCount,
    );

    return [
      for (final n in list)
        if (n.id == note.id) mergedNote else n,
    ];
  }

  void _upsertMetadata(int id, int folderId, String title) {
    final queue = _readQueue();
    final idx = queue.indexWhere(
      (op) => op.type == _NoteOpType.metadata && op.id == id,
    );
    final op = _NoteOp.metadata(id: id, folderId: folderId, title: title);
    _writeQueue(_replaceOrAppend(queue, idx, op));
  }

  void _upsertContent(int id, String title, List<NoteBlock> content) {
    final queue = _readQueue();
    final idx = queue.indexWhere(
      (op) => op.type == _NoteOpType.content && op.id == id,
    );
    final op = _NoteOp.content(id: id, title: title, content: content);
    _writeQueue(_replaceOrAppend(queue, idx, op));
  }

  void _upsertState(int id, bool? isPinned, bool? isArchived, bool? isLocked) {
    final queue = _readQueue();
    final idx = queue.indexWhere(
      (op) => op.type == _NoteOpType.state && op.id == id,
    );
    final merged = idx == -1
        ? _NoteOp.state(
            id: id,
            isPinned: isPinned,
            isArchived: isArchived,
            isLocked: isLocked,
          )
        : _NoteOp.state(
            id: id,
            isPinned: isPinned ?? queue[idx].isPinned,
            isArchived: isArchived ?? queue[idx].isArchived,
            isLocked: isLocked ?? queue[idx].isLocked,
          );
    _writeQueue(_replaceOrAppend(queue, idx, merged));
  }

  void _upsertDeleteRestore(int id, bool isDelete) {
    final queue = _readQueue();
    final idx = queue.indexWhere(
      (op) => op.type == _NoteOpType.deleteRestore && op.id == id,
    );
    final op = _NoteOp.deleteRestore(id: id, isDelete: isDelete);
    _writeQueue(_replaceOrAppend(queue, idx, op));
  }

  List<_NoteOp> _replaceOrAppend(List<_NoteOp> queue, int idx, _NoteOp op) {
    if (idx == -1) return [...queue, op];
    return [
      for (var i = 0; i < queue.length; i++)
        if (i == idx) op else queue[i],
    ];
  }

  _NoteOp _remapOp(_NoteOp op, Map<int, int> tempToReal) {
    final newId = tempToReal[op.id] ?? op.id;
    return switch (op.type) {
      _NoteOpType.metadata => _NoteOp.metadata(
        id: newId,
        folderId: op.folderId!,
        title: op.title!,
      ),
      _NoteOpType.content => _NoteOp.content(
        id: newId,
        title: op.title,
        content: op.content!,
      ),
      _NoteOpType.state => _NoteOp.state(
        id: newId,
        isPinned: op.isPinned,
        isArchived: op.isArchived,
        isLocked: op.isLocked,
      ),
      _NoteOpType.deleteRestore => _NoteOp.deleteRestore(
        id: newId,
        isDelete: op.isDelete!,
      ),
      _NoteOpType.attachment => _NoteOp.attachment(
        id: newId,
        filePath: op.filePath!,
        blockId: op.blockId!,
        displayOrder: op.displayOrder,
      ),
    };
  }

  Note _remapNote(Note n, Map<int, int> tempToReal) {
    final newId = tempToReal[n.id];
    if (newId == null) return n;
    return Note(
      id: newId,
      folderId: n.folderId,
      folderName: n.folderName,
      title: n.title,
      content: n.content,
      isPinned: n.isPinned,
      isArchived: n.isArchived,
      isLocked: n.isLocked,
      updatedAt: n.updatedAt,
      deletedAt: n.deletedAt,
      attachmentCount: n.attachmentCount,
    );
  }

  NoteBundle _bundle(List<Note> all, int? folderId) => NoteBundle(
    notes: all
        .where(
          (n) =>
              !n.isDeleted &&
              !n.isArchived &&
              (folderId == null || n.folderId == folderId),
        )
        .toList(),
    archive: all.where((n) => !n.isDeleted && n.isArchived).toList(),
    trash: all.where((n) => n.isDeleted).toList(),
  );

  Future<Result<AttachmentUpload>> _storeAttachmentLocallyAndQueue({
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
      final attachmentsDir = Directory(
        '${dir.path}/account_attachments_pending',
      );
      if (!attachmentsDir.existsSync()) {
        await attachmentsDir.create(recursive: true);
      }

      final id = _nextTempAttachmentId();
      final dot = filePath.lastIndexOf('.');
      final slash = filePath.lastIndexOf('/');
      final extension = (dot > slash) ? filePath.substring(dot) : '';
      final destPath = '${attachmentsDir.path}/$id$extension';
      final copied = await source.copy(destPath);

      await _writeQueue([
        ..._readQueue(),
        _NoteOp.attachment(
          id: noteId,
          filePath: copied.path,
          blockId: blockId,
          displayOrder: displayOrder,
        ),
      ]);

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

  Future<void> _deleteAttachmentFiles(Note note) async {
    for (final block in note.content.whereType<AttachmentBlock>()) {
      final path = block.localPath;
      if (path == null) continue;
      final file = File(path);
      if (file.existsSync()) await file.delete();
    }
  }

  // ── persistence ───────────────────────────────────────────────────────

  List<Note> _readCache() {
    final raw = _storage.read<List>(_cacheKey) ?? (_uid != 'unknown' ? _storage.read<List>('account_notes_cache_unknown') : null);
    if (raw == null) return <Note>[];
    return raw
        .whereType<Map>()
        .map((m) => _noteFromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> _writeCache(List<Note> notes) =>
      _storage.write(_cacheKey, notes.map(_noteToJson).toList());

  List<_NoteOp> _readQueue() {
    final raw = _storage.read<List>(_queueKey) ?? (_uid != 'unknown' ? _storage.read<List>('account_notes_queue_unknown') : null);
    if (raw == null) return <_NoteOp>[];
    return raw
        .whereType<Map>()
        .map((m) => _NoteOp.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> _writeQueue(List<_NoteOp> queue) =>
      _storage.write(_queueKey, queue.map((op) => op.toJson()).toList());

  int _nextTempId() {
    final next = (_storage.read<int>(_nextIdKey) ?? 0) - 1;
    _storage.write(_nextIdKey, next);
    return next;
  }

  int _nextTempAttachmentId() {
    final next = (_storage.read<int>(_nextAttachmentIdKey) ?? 0) - 1;
    _storage.write(_nextAttachmentIdKey, next);
    return next;
  }

  static Map<String, dynamic> _noteToJson(Note n) => {
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

  static Note _noteFromJson(Map<String, dynamic> j) => Note(
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
  /// The offline cache is the opposite: `localPath` is what makes an
  /// attachment block usable again — online or off — after a restart, so
  /// it's added back in, the same way `LocalNoteRepository` does for guests.
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

enum _NoteOpType { metadata, content, state, deleteRestore, attachment }

/// A queued note write that couldn't reach the server yet.
class _NoteOp {
  final _NoteOpType type;
  final int id;
  // metadata
  final int? folderId;
  final String? title;
  // content (also reuses `title`, matching saveNoteContent's own signature)
  final List<NoteBlock>? content;
  // state
  final bool? isPinned;
  final bool? isArchived;
  final bool? isLocked;
  // deleteRestore
  final bool? isDelete;
  // attachment
  final String? filePath;
  final String? blockId;
  final int? displayOrder;

  const _NoteOp._({
    required this.type,
    required this.id,
    this.folderId,
    this.title,
    this.content,
    this.isPinned,
    this.isArchived,
    this.isLocked,
    this.isDelete,
    this.filePath,
    this.blockId,
    this.displayOrder,
  });

  factory _NoteOp.metadata({
    required int id,
    required int folderId,
    required String title,
  }) => _NoteOp._(
    type: _NoteOpType.metadata,
    id: id,
    folderId: folderId,
    title: title,
  );

  factory _NoteOp.content({
    required int id,
    String? title,
    required List<NoteBlock> content,
  }) => _NoteOp._(
    type: _NoteOpType.content,
    id: id,
    title: title,
    content: content,
  );

  factory _NoteOp.state({
    required int id,
    bool? isPinned,
    bool? isArchived,
    bool? isLocked,
  }) => _NoteOp._(
    type: _NoteOpType.state,
    id: id,
    isPinned: isPinned,
    isArchived: isArchived,
    isLocked: isLocked,
  );

  factory _NoteOp.deleteRestore({required int id, required bool isDelete}) =>
      _NoteOp._(type: _NoteOpType.deleteRestore, id: id, isDelete: isDelete);

  factory _NoteOp.attachment({
    required int id,
    required String filePath,
    required String blockId,
    int? displayOrder,
  }) => _NoteOp._(
    type: _NoteOpType.attachment,
    id: id,
    filePath: filePath,
    blockId: blockId,
    displayOrder: displayOrder,
  );

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'id': id,
    'folderId': folderId,
    'title': title,
    'content': content?.map(NoteSyncRepository._blockToJson).toList(),
    'isPinned': isPinned,
    'isArchived': isArchived,
    'isLocked': isLocked,
    'isDelete': isDelete,
    'filePath': filePath,
    'blockId': blockId,
    'displayOrder': displayOrder,
  };

  static _NoteOp fromJson(Map<String, dynamic> j) {
    final type = _NoteOpType.values.firstWhere(
      (t) => t.name == j['type'],
      orElse: () => _NoteOpType.metadata,
    );
    final rawContent = j['content'] as List?;
    return _NoteOp._(
      type: type,
      id: j['id'] as int,
      folderId: j['folderId'] as int?,
      title: j['title'] as String?,
      content: rawContent
          ?.whereType<Map>()
          .map(
            (m) =>
                NoteSyncRepository._blockFromJson(Map<String, dynamic>.from(m)),
          )
          .toList(),
      isPinned: j['isPinned'] as bool?,
      isArchived: j['isArchived'] as bool?,
      isLocked: j['isLocked'] as bool?,
      isDelete: j['isDelete'] as bool?,
      filePath: j['filePath'] as String?,
      blockId: j['blockId'] as String?,
      displayOrder: j['displayOrder'] as int?,
    );
  }
}
