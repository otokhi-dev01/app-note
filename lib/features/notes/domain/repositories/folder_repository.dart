import '../entities/folder.dart';

abstract interface class FolderRepository {
  Future<List<Folder>> getFolders();
  Future<List<Folder>> getDeletedFolders();
  Future<int> createFolder(String name);
  Future<int> renameFolder(int id, String newName);
  Future<int> deleteFolder(int id);
  Future<int> restoreFolder(int id);
}
