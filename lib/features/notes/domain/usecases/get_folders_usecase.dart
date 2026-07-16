import '../entities/folder.dart';
import '../repositories/folder_repository.dart';

class GetFoldersUseCase {
  const GetFoldersUseCase(this.repository);

  final FolderRepository repository;

  Future<List<Folder>> call() {
    return repository.getFolders();
  }
}
