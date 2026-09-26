import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:Note/core/error/failures.dart';
import 'package:Note/core/error/result.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/features/folder/domain/entities/folder.dart';
import 'package:Note/features/folder/domain/repositories/folder_repository.dart';

/// Lets a signed-in account keep using folders while offline.
///
/// Wraps the real [FolderRepository] (`FolderRepositoryImpl`) with an
/// on-device cache and a queue of writes that could not reach the server.
/// Reads are served from a merge of the last server snapshot and any writes
/// still waiting to sync; writes apply to the cache immediately — so the UI
/// never blocks on connectivity — and are queued for replay the next time
/// the server answers.
///
/// A [NetworkFailure] from the wrapped repository (connection timeout, DNS
/// failure, no signal) is the only failure this treats as "offline". Every
/// other failure — auth, validation, a real server error, the backend's
/// permanent-delete being unsupported — passes straight through, exactly as
/// it would online: this is a connectivity fallback, not a general retry.
///
/// Only used for signed-in accounts, wired in as the "remote" side of
/// `FolderRepositoryRouter` — guest mode has its own always-local, never-synced
/// `LocalFolderRepository`.
class FolderSyncRepository implements FolderRepository {
  final FolderRepository _remote;
  final SessionStorage _session;
  final _storage = GetStorage();

  FolderSyncRepository(this._remote, this._session);

  /// Namespaced per signed-in account so switching accounts on one device
  /// never mixes caches, and so a stale cache can't survive as a different
  /// user's data.
  String get _uid => _session.user.value?.id ?? 'unknown';
  String get _cacheKey => 'account_folders_cache_$_uid';
  String get _queueKey => 'account_folders_queue_$_uid';
  String get _nextIdKey => 'account_folders_next_id_$_uid';
  String get _tempMapKey => 'account_folders_temp_map_$_uid';

  /// Writes still waiting to reach the server — exposed so the UI can show a
  /// "syncing…" indicator if it wants one.
  int get pendingCount => _readQueue().length;

  /// The real, server-assigned id for [id] once known, or [id] unchanged —
  /// already real, or a temp id not yet synced. Used by `NoteSyncRepository`
  /// to translate a note's `folderId` when that folder was itself created
  /// offline and has since synced.
  int resolveId(int id) => id >= 0 ? id : (_readTempMap()[id] ?? id);

  bool _isOfflineOrAuthFailure(AppFailure failure) {
    if (failure is NetworkFailure) return true;
    if (kDebugMode) {
      if (failure is UnauthorizedFailure) return true;
      if (failure is ServerFailure && failure.statusCode == 401) return true;
    }
    return false;
  }

  @override
  Future<Result<FolderBundle>> getFolders() async {
    await flushPending();

    final result = await _remote.getFolders();
    switch (result) {
      case Ok(:final value):
        var list = [...value.folders, ...value.trash];
        // Anything still queued (a write made in the gap since flushPending
        // above, or one that failed to flush for a non-network reason and
        // was intentionally dropped — see flushPending) is re-applied on top
        // of the fresh server snapshot so it isn't lost from this read.
        for (final op in _readQueue()) {
          list = _apply(list, op);
        }
        await _writeCache(list);
        return Ok(_bundle(list));
      case Err(:final failure):
        if (!_isOfflineOrAuthFailure(failure)) return Err(failure);
        return Ok(_bundle(_readCache()));
    }
  }

  @override
  Future<Result<int>> saveFolder({
    required int id,
    int? parentId,
    required String name,
    required String iconName,
    required String colorValue,
    int sortOrder = 0,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const Err(ValidationFailure('Folder name cannot be empty.'));
    }

    // A still-unsynced local folder: the server has never heard of `id`, so
    // there is nothing to call — apply the edit locally and fold it into the
    // still-queued create instead of piling up a second op for it.
    if (id < 0) {
      await _writeCache(
        _apply(
          _readCache(),
          _FolderOp.save(
            id: id,
            parentId: parentId,
            name: trimmed,
            iconName: iconName,
            colorValue: colorValue,
            sortOrder: sortOrder,
          ),
        ),
      );
      _upsertSave(id, parentId, trimmed, iconName, colorValue, sortOrder);
      return Ok(id);
    }

    final result = await _remote.saveFolder(
      id: id,
      parentId: parentId,
      name: trimmed,
      iconName: iconName,
      colorValue: colorValue,
      sortOrder: sortOrder,
    );
    switch (result) {
      case Ok(:final value):
        await _writeCache(
          _apply(
            _readCache(),
            _FolderOp.save(
              id: value,
              parentId: parentId,
              name: trimmed,
              iconName: iconName,
              colorValue: colorValue,
              sortOrder: sortOrder,
            ),
          ),
        );
        return Ok(value);
      case Err(:final failure):
        if (!_isOfflineOrAuthFailure(failure)) return Err(failure);
        final assignedId = id == 0 ? _nextTempId() : id;
        await _writeCache(
          _apply(
            _readCache(),
            _FolderOp.save(
              id: assignedId,
              parentId: parentId,
              name: trimmed,
              iconName: iconName,
              colorValue: colorValue,
              sortOrder: sortOrder,
            ),
          ),
        );
        _upsertSave(
          assignedId,
          parentId,
          trimmed,
          iconName,
          colorValue,
          sortOrder,
        );
        return Ok(assignedId);
    }
  }

  @override
  Future<Result<void>> deleteRestoreFolder(int folderId, bool isDelete) async {
    if (folderId < 0) {
      await _writeCache(
        _apply(
          _readCache(),
          _FolderOp.deleteRestore(id: folderId, isDelete: isDelete),
        ),
      );
      _upsertDeleteRestore(folderId, isDelete);
      return okVoid;
    }

    final result = await _remote.deleteRestoreFolder(folderId, isDelete);
    switch (result) {
      case Ok():
        await _writeCache(
          _apply(
            _readCache(),
            _FolderOp.deleteRestore(id: folderId, isDelete: isDelete),
          ),
        );
        return okVoid;
      case Err(:final failure):
        if (!_isOfflineOrAuthFailure(failure)) return Err(failure);
        await _writeCache(
          _apply(
            _readCache(),
            _FolderOp.deleteRestore(id: folderId, isDelete: isDelete),
          ),
        );
        _upsertDeleteRestore(folderId, isDelete);
        return okVoid;
    }
  }

  @override
  Future<Result<void>> deleteFolderPermanently(int folderId) async {
    if (folderId < 0) {
      // Never reached the server — nothing to delete there. Forget it
      // locally, cache and any queued ops for it alike.
      await _writeCache(_readCache()..removeWhere((f) => f.id == folderId));
      await _writeQueue(_readQueue()..removeWhere((op) => op.id == folderId));
      return okVoid;
    }
    return _remote.deleteFolderPermanently(folderId);
  }

  /// The display name for [folderId] — used by `NoteSyncRepository` so a
  /// note saved offline can show which folder it lives in without a network
  /// round trip.
  String folderNameOf(int folderId) {
    final match = _readCache().where((f) => f.id == folderId).firstOrNull;
    return match?.name ?? 'Notes';
  }

  /// Replays queued writes against the server, in the order they were made
  /// (a folder's create always sits before any of its own later edits or its
  /// children's creates, since none of those can happen in the app before
  /// the folder itself exists).
  ///
  /// Stops queuing further network calls the moment one comes back
  /// [NetworkFailure] — still offline — and leaves that op and everything
  /// behind it queued for next time. Any other failure (the folder was
  /// deleted server-side from another device, a validation error) drops
  /// just that one op: it didn't fail because of connectivity, so retrying
  /// it later would only fail the same way again, and it must not block
  /// every op behind it forever.
  Future<void> flushPending() async {
    final queue = _readQueue();
    if (queue.isEmpty) return;

    final tempToReal = <int, int>{};
    final stillQueued = <_FolderOp>[];
    var offline = false;

    for (final op in queue) {
      final remapped = _remap(op, tempToReal);
      if (offline) {
        stillQueued.add(remapped);
        continue;
      }

      switch (remapped.type) {
        case _FolderOpType.save:
          final result = await _remote.saveFolder(
            id: remapped.id < 0 ? 0 : remapped.id,
            parentId: remapped.parentId,
            name: remapped.name!,
            iconName: remapped.iconName!,
            colorValue: remapped.colorValue!,
            sortOrder: remapped.sortOrder!,
          );
          switch (result) {
            case Ok(:final value):
              if (remapped.id < 0) tempToReal[remapped.id] = value;
            case Err(:final failure):
              if (_isOfflineOrAuthFailure(failure)) {
                offline = true;
                stillQueued.add(remapped);
              }
          }
        case _FolderOpType.deleteRestore:
          final result = await _remote.deleteRestoreFolder(
            remapped.id,
            remapped.isDelete!,
          );
          if (result
              case Err(:final failure)
              when _isOfflineOrAuthFailure(failure)) {
            offline = true;
            stillQueued.add(remapped);
          }
      }
    }

    await _writeQueue(stillQueued);
    if (tempToReal.isNotEmpty) {
      final remappedCache = _readCache()
          .map((f) => _remapFolder(f, tempToReal))
          .toList();
      await _writeCache(remappedCache);
      await _writeTempMap({..._readTempMap(), ...tempToReal});
    }
  }

  // ── cache/queue mutation helpers ─────────────────────────────────────

  List<Folder> _apply(List<Folder> list, _FolderOp op) {
    final now = DateTime.now();
    final idx = list.indexWhere((f) => f.id == op.id);

    switch (op.type) {
      case _FolderOpType.save:
        if (idx == -1) {
          return [
            ...list,
            Folder(
              id: op.id,
              parentId: op.parentId,
              name: op.name!,
              iconName: op.iconName!,
              colorValue: op.colorValue!,
              sortOrder: op.sortOrder!,
              createdAt: now,
              updatedAt: now,
            ),
          ];
        }
        final existing = list[idx];
        final updated = Folder(
          id: existing.id,
          parentId: op.parentId,
          name: op.name!,
          iconName: op.iconName!,
          colorValue: op.colorValue!,
          sortOrder: op.sortOrder!,
          noteCount: existing.noteCount,
          createdAt: existing.createdAt ?? now,
          updatedAt: now,
          deletedAt: existing.deletedAt,
          hasChildren: existing.hasChildren,
        );
        return [
          for (final f in list)
            if (f.id == op.id) updated else f,
        ];
      case _FolderOpType.deleteRestore:
        if (idx == -1) return list;
        final existing = list[idx];
        final updated = Folder(
          id: existing.id,
          parentId: existing.parentId,
          name: existing.name,
          iconName: existing.iconName,
          colorValue: existing.colorValue,
          sortOrder: existing.sortOrder,
          noteCount: existing.noteCount,
          createdAt: existing.createdAt,
          updatedAt: now,
          deletedAt: op.isDelete! ? now : null,
          hasChildren: existing.hasChildren,
        );
        return [
          for (final f in list)
            if (f.id == op.id) updated else f,
        ];
    }
  }

  /// Inserts a new queued create/edit, or — if this exact folder already has
  /// one queued — updates it in place so repeated offline edits collapse
  /// into the one op that matters (the latest), without moving it past a
  /// later op for a different folder.
  void _upsertSave(
    int id,
    int? parentId,
    String name,
    String iconName,
    String colorValue,
    int sortOrder,
  ) {
    final queue = _readQueue();
    final idx = queue.indexWhere(
      (op) => op.type == _FolderOpType.save && op.id == id,
    );
    final op = _FolderOp.save(
      id: id,
      parentId: parentId,
      name: name,
      iconName: iconName,
      colorValue: colorValue,
      sortOrder: sortOrder,
    );
    if (idx == -1) {
      _writeQueue([...queue, op]);
    } else {
      _writeQueue([
        for (var i = 0; i < queue.length; i++)
          if (i == idx) op else queue[i],
      ]);
    }
  }

  void _upsertDeleteRestore(int id, bool isDelete) {
    final queue = _readQueue();
    final idx = queue.indexWhere(
      (op) => op.type == _FolderOpType.deleteRestore && op.id == id,
    );
    final op = _FolderOp.deleteRestore(id: id, isDelete: isDelete);
    if (idx == -1) {
      _writeQueue([...queue, op]);
    } else {
      _writeQueue([
        for (var i = 0; i < queue.length; i++)
          if (i == idx) op else queue[i],
      ]);
    }
  }

  _FolderOp _remap(_FolderOp op, Map<int, int> tempToReal) {
    final newId = tempToReal[op.id] ?? op.id;
    final newParentId = tempToReal[op.parentId] ?? op.parentId;
    return op.type == _FolderOpType.save
        ? _FolderOp.save(
            id: newId,
            parentId: newParentId,
            name: op.name!,
            iconName: op.iconName!,
            colorValue: op.colorValue!,
            sortOrder: op.sortOrder!,
          )
        : _FolderOp.deleteRestore(id: newId, isDelete: op.isDelete!);
  }

  Folder _remapFolder(Folder f, Map<int, int> tempToReal) {
    final newId = tempToReal[f.id];
    final newParentId = tempToReal[f.parentId] ?? f.parentId;
    if (newId == null && newParentId == f.parentId) return f;
    return Folder(
      id: newId ?? f.id,
      parentId: newParentId,
      name: f.name,
      iconName: f.iconName,
      colorValue: f.colorValue,
      sortOrder: f.sortOrder,
      noteCount: f.noteCount,
      createdAt: f.createdAt,
      updatedAt: f.updatedAt,
      deletedAt: f.deletedAt,
      hasChildren: f.hasChildren,
    );
  }

  FolderBundle _bundle(List<Folder> list) => FolderBundle(
    folders: list.where((f) => !f.isDeleted).toList(),
    trash: list.where((f) => f.isDeleted).toList(),
  );

  // ── persistence ───────────────────────────────────────────────────────

  List<Folder> _readCache() {
    final raw = _storage.read<List>(_cacheKey) ?? (_uid != 'unknown' ? _storage.read<List>('account_folders_cache_unknown') : null);
    if (raw == null) return <Folder>[];
    return raw
        .whereType<Map>()
        .map((m) => _folderFromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> _writeCache(List<Folder> folders) =>
      _storage.write(_cacheKey, folders.map(_folderToJson).toList());

  List<_FolderOp> _readQueue() {
    final raw = _storage.read<List>(_queueKey) ?? (_uid != 'unknown' ? _storage.read<List>('account_folders_queue_unknown') : null);
    if (raw == null) return <_FolderOp>[];
    return raw
        .whereType<Map>()
        .map((m) => _FolderOp.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> _writeQueue(List<_FolderOp> queue) =>
      _storage.write(_queueKey, queue.map((op) => op.toJson()).toList());

  int _nextTempId() {
    final next = (_storage.read<int>(_nextIdKey) ?? 0) - 1;
    _storage.write(_nextIdKey, next);
    return next;
  }

  /// Every temp id this device has ever resolved to a real one, kept
  /// forever (never pruned) so a note created offline can still resolve its
  /// `folderId` even after the folder itself has long since synced and left
  /// the pending queue.
  Map<int, int> _readTempMap() {
    final raw = _storage.read<Map>(_tempMapKey) ?? (_uid != 'unknown' ? _storage.read<Map>('account_folders_temp_map_unknown') : null);
    if (raw == null) return <int, int>{};
    return raw.map((k, v) => MapEntry(int.parse(k.toString()), v as int));
  }

  Future<void> _writeTempMap(Map<int, int> map) =>
      _storage.write(_tempMapKey, map.map((k, v) => MapEntry(k.toString(), v)));

  static Map<String, dynamic> _folderToJson(Folder f) => {
    'id': f.id,
    'parentId': f.parentId,
    'name': f.name,
    'iconName': f.iconName,
    'colorValue': f.colorValue,
    'sortOrder': f.sortOrder,
    'noteCount': f.noteCount,
    'createdAt': f.createdAt?.toIso8601String(),
    'updatedAt': f.updatedAt?.toIso8601String(),
    'deletedAt': f.deletedAt?.toIso8601String(),
    'hasChildren': f.hasChildren,
  };

  static Folder _folderFromJson(Map<String, dynamic> j) => Folder(
    id: j['id'] as int,
    parentId: j['parentId'] as int?,
    name: j['name'] as String? ?? '',
    iconName: j['iconName'] as String? ?? '',
    colorValue: j['colorValue'] as String? ?? '',
    sortOrder: j['sortOrder'] as int? ?? 0,
    noteCount: j['noteCount'] as int? ?? 0,
    createdAt: _parseDate(j['createdAt']),
    updatedAt: _parseDate(j['updatedAt']),
    deletedAt: _parseDate(j['deletedAt']),
    hasChildren: j['hasChildren'] as bool? ?? false,
  );

  static DateTime? _parseDate(dynamic v) =>
      v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;
}

enum _FolderOpType { save, deleteRestore }

/// A queued folder write that couldn't reach the server yet.
class _FolderOp {
  final _FolderOpType type;
  final int id;
  final int? parentId;
  final String? name;
  final String? iconName;
  final String? colorValue;
  final int? sortOrder;
  final bool? isDelete;

  const _FolderOp._({
    required this.type,
    required this.id,
    this.parentId,
    this.name,
    this.iconName,
    this.colorValue,
    this.sortOrder,
    this.isDelete,
  });

  factory _FolderOp.save({
    required int id,
    int? parentId,
    required String name,
    required String iconName,
    required String colorValue,
    required int sortOrder,
  }) => _FolderOp._(
    type: _FolderOpType.save,
    id: id,
    parentId: parentId,
    name: name,
    iconName: iconName,
    colorValue: colorValue,
    sortOrder: sortOrder,
  );

  factory _FolderOp.deleteRestore({required int id, required bool isDelete}) =>
      _FolderOp._(
        type: _FolderOpType.deleteRestore,
        id: id,
        isDelete: isDelete,
      );

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'id': id,
    'parentId': parentId,
    'name': name,
    'iconName': iconName,
    'colorValue': colorValue,
    'sortOrder': sortOrder,
    'isDelete': isDelete,
  };

  static _FolderOp fromJson(Map<String, dynamic> j) {
    final type = j['type'] == 'deleteRestore'
        ? _FolderOpType.deleteRestore
        : _FolderOpType.save;
    return _FolderOp._(
      type: type,
      id: j['id'] as int,
      parentId: j['parentId'] as int?,
      name: j['name'] as String?,
      iconName: j['iconName'] as String?,
      colorValue: j['colorValue'] as String?,
      sortOrder: j['sortOrder'] as int?,
      isDelete: j['isDelete'] as bool?,
    );
  }
}
