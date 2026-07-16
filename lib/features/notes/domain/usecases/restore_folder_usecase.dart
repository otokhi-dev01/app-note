import '../repositories/folder_repository.dart';

class RestoreFolderUseCase {
  const RestoreFolderUseCase(this.repository);

  final FolderRepository repository;

  Future<int> call(int id) {
    return repository.restoreFolder(id);
  }
}
