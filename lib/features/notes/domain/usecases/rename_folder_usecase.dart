import '../repositories/folder_repository.dart';

class RenameFolderUseCase {
  const RenameFolderUseCase(this.repository);

  final FolderRepository repository;

  Future<int> call(int id, String newName) {
    return repository.renameFolder(id, newName);
  }
}
