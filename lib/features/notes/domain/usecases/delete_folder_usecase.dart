import '../repositories/folder_repository.dart';

class DeleteFolderUseCase {
  const DeleteFolderUseCase(this.repository);

  final FolderRepository repository;

  Future<int> call(int id) {
    return repository.deleteFolder(id);
  }
}
