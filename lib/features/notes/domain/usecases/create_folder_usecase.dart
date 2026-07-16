import '../repositories/folder_repository.dart';

class CreateFolderUseCase {
  const CreateFolderUseCase(this.repository);

  final FolderRepository repository;

  Future<int> call(String name) {
    return repository.createFolder(name);
  }
}
