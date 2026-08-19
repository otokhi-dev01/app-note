import 'package:Note/core/error/result.dart';
import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/features/folder/data/repositories/local_folder_repository.dart';
import 'package:Note/features/folder/domain/entities/folder.dart';
import 'package:Note/features/folder/domain/repositories/folder_repository.dart';

/// Sends every call to on-device storage while in guest mode, and to the real
/// backend otherwise — the one seam that lets `FolderController` and every
/// folder use case stay unaware that guest mode exists at all.
class FolderRepositoryRouter implements FolderRepository {
  final FolderRepository _remote;
  final LocalFolderRepository _local;
  final GuestModeService _guestMode;

  const FolderRepositoryRouter(this._remote, this._local, this._guestMode);

  FolderRepository get _active => _guestMode.isGuestMode.value ? _local : _remote;

  @override
  Future<Result<FolderBundle>> getFolders() => _active.getFolders();

  @override
  Future<Result<int>> saveFolder({
    required int id,
    int? parentId,
    required String name,
    required String iconName,
    required String colorValue,
    int sortOrder = 0,
  }) => _active.saveFolder(
    id: id,
    parentId: parentId,
    name: name,
    iconName: iconName,
    colorValue: colorValue,
    sortOrder: sortOrder,
  );

  @override
  Future<Result<void>> deleteRestoreFolder(int folderId, bool isDelete) =>
      _active.deleteRestoreFolder(folderId, isDelete);

  @override
  Future<Result<void>> deleteFolderPermanently(int folderId) =>
      _active.deleteFolderPermanently(folderId);
}
