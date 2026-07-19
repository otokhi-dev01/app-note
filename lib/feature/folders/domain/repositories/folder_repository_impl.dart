import '../entities/folder_entity.dart';

abstract class FolderRepository {
  /// Get all folders for the authenticated user.
  Future<List<FolderEntity>> getFolders();

  /// Create or update a folder.
  ///
  /// Usually:
  /// - id = 0 creates a new folder
  /// - id > 0 updates an existing folder
  Future<void> saveFolder({
    required int id,
    required String name,
    required String iconName,
    required String colorValue,
    required int sortOrder,
  });

  /// Soft-delete or restore a folder.
  ///
  /// - isDelete = true deletes the folder
  /// - isDelete = false restores the folder
  Future<void> deleteOrRestoreFolder({
    required int id,
    required bool isDelete,
  });
}