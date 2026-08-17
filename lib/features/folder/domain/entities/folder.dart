/// A folder as the app reasons about it — pure Dart.
///
/// The `IconData` / `Color` this renders as are deliberately *not* here: that
/// mapping is a presentation concern and lives in the `FolderAppearanceX`
/// extension in `core/theme/folder_appearance.dart`.
class Folder {
  final int id;
  final int? parentId;
  final String name;
  final String iconName;
  final String colorValue;
  final int sortOrder;
  final int noteCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final List<Folder> subFolders;

  const Folder({
    required this.id,
    this.parentId,
    required this.name,
    required this.iconName,
    required this.colorValue,
    required this.sortOrder,
    this.noteCount = 0,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.subFolders = const [],
  });

  bool get isDeleted => deletedAt != null;

  bool get isRoot => parentId == null || parentId == 0;

  Folder copyWith({List<Folder>? subFolders}) => Folder(
    id: id,
    parentId: parentId,
    name: name,
    iconName: iconName,
    colorValue: colorValue,
    sortOrder: sortOrder,
    noteCount: noteCount,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
    subFolders: subFolders ?? this.subFolders,
  );
}

/// Active folders and trashed folders from a single fetch.
class FolderBundle {
  final List<Folder> folders;
  final List<Folder> trash;

  const FolderBundle({this.folders = const [], this.trash = const []});
}
