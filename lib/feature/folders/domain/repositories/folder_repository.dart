import 'package:note_app/feature/folders/domain/entities/folder_entity.dart';

abstract class FolderRepository {
  Future<List<FolderEntity>> getFolders();

  Future<void> saveFolder({
    required int id,
    required String name,
    required String iconName,
    required String colorValue,
    required int sortOrder,
  });

  Future<void> deleteOrRestoreFolder({required int id, required bool isDelete});
}
