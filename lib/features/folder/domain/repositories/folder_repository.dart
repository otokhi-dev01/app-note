import 'package:Note/core/error/result.dart';
import 'package:Note/features/folder/domain/entities/folder.dart';

abstract class FolderRepository {
  Future<Result<FolderBundle>> getFolders();

  /// Creates when [id] is 0, updates otherwise. Resolves to the saved folder's
  /// id so callers can select it afterwards. [parentId] nests the folder
  /// under another one; leave it null (or 0) to save it at the root.
  Future<Result<int>> saveFolder({
    required int id,
    int? parentId,
    required String name,
    required String iconName,
    required String colorValue,
    int sortOrder = 0,
  });

  Future<Result<void>> deleteRestoreFolder(int folderId, bool isDelete);

  /// Unsupported by the current backend — always fails with
  /// [UnsupportedFeatureFailure].
  Future<Result<void>> deleteFolderPermanently(int folderId);
}
