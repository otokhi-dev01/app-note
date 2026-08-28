import 'package:Note/core/error/result.dart';
import 'package:Note/core/usecase/usecase.dart';
import 'package:Note/features/folder/domain/entities/folder.dart';
import 'package:Note/features/folder/domain/repositories/folder_repository.dart';

class GetFolders extends UseCase<FolderBundle, NoParams> {
  final FolderRepository _repository;

  const GetFolders(this._repository);

  @override
  Future<Result<FolderBundle>> call(NoParams params) =>
      _repository.getFolders();
}

class SaveFolder extends UseCase<int, SaveFolderParams> {
  final FolderRepository _repository;

  const SaveFolder(this._repository);

  @override
  Future<Result<int>> call(SaveFolderParams params) => _repository.saveFolder(
    id: params.id,
    parentId: params.parentId,
    name: params.name,
    iconName: params.iconName,
    colorValue: params.colorValue,
    sortOrder: params.sortOrder,
  );
}

class SaveFolderParams {
  final int id;
  final int? parentId;
  final String name;
  final String iconName;
  final String colorValue;
  final int sortOrder;

  const SaveFolderParams({
    this.id = 0,
    this.parentId,
    required this.name,
    required this.iconName,
    required this.colorValue,
    this.sortOrder = 0,
  });

  bool get isCreate => id == 0;
}

class DeleteRestoreFolder extends UseCase<void, DeleteRestoreFolderParams> {
  final FolderRepository _repository;

  const DeleteRestoreFolder(this._repository);

  @override
  Future<Result<void>> call(DeleteRestoreFolderParams params) =>
      _repository.deleteRestoreFolder(params.folderId, params.isDelete);
}

class DeleteRestoreFolderParams {
  final int folderId;
  final bool isDelete;

  const DeleteRestoreFolderParams({
    required this.folderId,
    required this.isDelete,
  });
}

class DeleteFolderPermanently extends UseCase<void, int> {
  final FolderRepository _repository;

  const DeleteFolderPermanently(this._repository);

  @override
  Future<Result<void>> call(int folderId) =>
      _repository.deleteFolderPermanently(folderId);
}

/// Turns the flat list the API returns into a parent/child tree.
///
/// Pure and synchronous — extracted from `FolderController._buildHierarchy`,
/// where it was the one piece of real domain logic sitting in presentation.
/// Being a plain function of a list makes it directly unit-testable.
class BuildFolderHierarchy extends SyncUseCase<List<Folder>, List<Folder>> {
  const BuildFolderHierarchy();

  @override
  Result<List<Folder>> call(List<Folder> flat) {
    final Map<int, List<Folder>> childrenOf = {};
    final List<Folder> roots = [];

    for (final folder in flat) {
      if (folder.isRoot) {
        roots.add(folder);
      } else {
        childrenOf.putIfAbsent(folder.parentId!, () => []).add(folder);
      }
    }

    // Guard against a folder that lists itself (directly or transitively) as an
    // ancestor — a cycle in the data would otherwise recurse until the stack
    // overflows.
    List<Folder> attach(List<Folder> level, Set<int> seen) => level.map((f) {
      if (seen.contains(f.id)) return f.copyWith(subFolders: const []);
      return f.copyWith(
        subFolders: attach(childrenOf[f.id] ?? const [], {...seen, f.id}),
      );
    }).toList();

    return Ok(attach(roots, const {}));
  }
}
