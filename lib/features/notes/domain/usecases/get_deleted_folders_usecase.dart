import '../entities/folder.dart';
import '../repositories/folder_repository.dart';

class GetDeletedFoldersUseCase {
  const GetDeletedFoldersUseCase(this.repository);

  final FolderRepository repository;

  Future<List<Folder>> call() {
    return repository.getDeletedFolders();
  }
}
