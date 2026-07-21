import '../../domain/entities/folder_entity.dart';

class FolderCollectionResponse {
  final List<FolderEntity> folders;
  final bool includesDeletedCollection;

  const FolderCollectionResponse({
    required this.folders,
    required this.includesDeletedCollection,
  });
}
