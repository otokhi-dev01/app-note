import 'package:get_storage/get_storage.dart';

import 'package:Note/core/error/failures.dart';
import 'package:Note/core/error/result.dart';
import 'package:Note/core/theme/folder_appearance.dart';
import 'package:Note/features/folder/domain/entities/folder.dart';
import 'package:Note/features/folder/domain/repositories/folder_repository.dart';

/// On-device storage for guest-mode folders — no network, no account.
///
/// Only ever exercised while `GuestModeService.isGuestMode` is true, via
/// `FolderRepositoryRouter`. IDs count down from -1 so they can never collide
/// with a server-assigned id if this device later signs into a real account.
class LocalFolderRepository implements FolderRepository {
  static const _foldersKey = 'guest_folders';
  static const _nextIdKey = 'guest_next_folder_id';

  final _storage = GetStorage();

  @override
  Future<Result<FolderBundle>> getFolders() async {
    final all = _readAll();
    return Ok(
      FolderBundle(
        folders: all.where((f) => !f.isDeleted).toList(),
        trash: all.where((f) => f.isDeleted).toList(),
      ),
    );
  }

  /// The display name for [folderId], for notes that need to report which
  /// folder they live in without a network round trip.
  String folderNameOf(int folderId) {
    final match = _readAll().where((f) => f.id == folderId).firstOrNull;
    return match?.name ?? 'Notes';
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

    final all = _readAll();
    final now = DateTime.now();

    if (id == 0) {
      final folder = Folder(
        id: _nextId(),
        parentId: parentId,
        name: trimmed,
        iconName: iconName,
        colorValue: colorValue,
        sortOrder: sortOrder,
        createdAt: now,
        updatedAt: now,
      );
      all.add(folder);
      await _writeAll(all);
      return Ok(folder.id);
    }

    final index = all.indexWhere((f) => f.id == id);
    if (index == -1) return const Err(ServerFailure('Folder not found.'));

    final existing = all[index];
    all[index] = Folder(
      id: existing.id,
      parentId: parentId ?? existing.parentId,
      name: trimmed,
      iconName: iconName,
      colorValue: colorValue,
      sortOrder: sortOrder,
      noteCount: existing.noteCount,
      createdAt: existing.createdAt,
      updatedAt: now,
      deletedAt: existing.deletedAt,
    );
    await _writeAll(all);
    return Ok(id);
  }

  @override
  Future<Result<void>> deleteRestoreFolder(int folderId, bool isDelete) async {
    final all = _readAll();
    final index = all.indexWhere((f) => f.id == folderId);
    if (index == -1) return const Err(ServerFailure('Folder not found.'));

    final existing = all[index];
    all[index] = Folder(
      id: existing.id,
      parentId: existing.parentId,
      name: existing.name,
      iconName: existing.iconName,
      colorValue: existing.colorValue,
      sortOrder: existing.sortOrder,
      noteCount: existing.noteCount,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
      deletedAt: isDelete ? DateTime.now() : null,
    );
    await _writeAll(all);
    return okVoid;
  }

  /// Unlike the real backend, guest data is entirely local — a permanent
  /// delete can just remove the row.
  @override
  Future<Result<void>> deleteFolderPermanently(int folderId) async {
    final all = _readAll()..removeWhere((f) => f.id == folderId);
    await _writeAll(all);
    return okVoid;
  }

  /// Clears every locally-stored guest folder — used when an account is
  /// deleted or when guest data should not carry over to a signed-in session.
  Future<void> clear() async {
    await _storage.remove(_foldersKey);
    await _storage.remove(_nextIdKey);
  }

  List<Folder> _readAll() {
    final raw = _storage.read<List>(_foldersKey);
    if (raw == null) {
      final seeded = [_defaultFolder()];
      _writeAll(seeded);
      return seeded;
    }
    return raw
        .whereType<Map>()
        .map((m) => _fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> _writeAll(List<Folder> folders) =>
      _storage.write(_foldersKey, folders.map(_toJson).toList());

  int _nextId() {
    final next = (_storage.read<int>(_nextIdKey) ?? 0) - 1;
    _storage.write(_nextIdKey, next);
    return next;
  }

  Folder _defaultFolder() {
    final now = DateTime.now();
    return Folder(
      id: _nextId(),
      name: 'Notes',
      iconName: FolderAppearance.defaultIconName,
      colorValue: FolderAppearance.defaultColorValue,
      sortOrder: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  static Map<String, dynamic> _toJson(Folder f) => {
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
  };

  static Folder _fromJson(Map<String, dynamic> j) => Folder(
    id: j['id'] as int,
    parentId: j['parentId'] as int?,
    name: j['name'] as String? ?? '',
    iconName: j['iconName'] as String? ?? FolderAppearance.defaultIconName,
    colorValue:
        j['colorValue'] as String? ?? FolderAppearance.defaultColorValue,
    sortOrder: j['sortOrder'] as int? ?? 0,
    noteCount: j['noteCount'] as int? ?? 0,
    createdAt: _parseDate(j['createdAt']),
    updatedAt: _parseDate(j['updatedAt']),
    deletedAt: _parseDate(j['deletedAt']),
  );

  static DateTime? _parseDate(dynamic v) =>
      v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;
}
