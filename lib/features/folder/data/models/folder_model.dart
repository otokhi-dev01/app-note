import 'package:Note/core/utils/json_parsers.dart';
import 'package:Note/features/folder/domain/entities/folder.dart';

/// [Folder] plus the wire format.
class FolderModel extends Folder {
  const FolderModel({
    required super.id,
    super.parentId,
    required super.name,
    required super.iconName,
    required super.colorValue,
    required super.sortOrder,
    super.noteCount,
    super.createdAt,
    super.updatedAt,
    super.deletedAt,
    super.subFolders,
    super.hasChildren,
  });

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    final rawSubs = json['SubFolders'] ?? json['subFolders'];
    final subs = (rawSubs is List ? rawSubs : const [])
        .whereType<Map>()
        .map((e) => FolderModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return FolderModel(
      id: asInt(json['FolderId'] ?? json['id'] ?? json['Id']),
      parentId: asInt(
        json['ParentFolderId'] ?? json['parentFolderId'] ?? json['ParentId'] ?? json['parentId'],
      ),
      name: asString(json['FolderName'] ?? json['Name'] ?? json['name']).trim(),
      iconName: asString(json['IconName'] ?? json['iconName']),
      colorValue: asString(json['ColorValue'] ?? json['colorValue']),
      sortOrder: asInt(json['SortOrder'] ?? json['sortOrder']),
      noteCount: asInt(json['NoteCount'] ?? json['noteCount']),
      createdAt: asDate(json['CreatedAt'] ?? json['createdAt']),
      updatedAt: asDate(json['UpdatedAt'] ?? json['updatedAt']),
      deletedAt: asDate(json['DeletedAt'] ?? json['deletedAt']),
      subFolders: subs,
      hasChildren: asBool(json['HasChildren'] ?? json['hasChildren']),
    );
  }

  /// Rebuilds a model from any [Folder], so use-case output can be handed back
  /// to code that still expects the model type.
  factory FolderModel.fromEntity(Folder folder) => FolderModel(
    id: folder.id,
    parentId: folder.parentId,
    name: folder.name,
    iconName: folder.iconName,
    colorValue: folder.colorValue,
    sortOrder: folder.sortOrder,
    noteCount: folder.noteCount,
    createdAt: folder.createdAt,
    updatedAt: folder.updatedAt,
    deletedAt: folder.deletedAt,
    subFolders: folder.subFolders,
    hasChildren: folder.hasChildren,
  );

  /// Matches `FolderSaveRequest`:
  /// `{ id, name*, iconName, colorValue, sortOrder, parentFolderId }`.
  /// `parentFolderId: null` saves it as a root folder.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'iconName': iconName,
    'colorValue': colorValue,
    'sortOrder': sortOrder,
    'parentFolderId': isRoot ? null : parentId,
  };
}

/// The `/api/folder` envelope.
///
/// Soft-deleted folders show up inside the active lists as well as under
/// `trash`, so both sources are merged and then split on `deletedAt`.
class FolderResponse {
  final List<FolderModel> folders;
  final List<FolderModel> trash;
  final int code;
  final String message;

  const FolderResponse({
    required this.folders,
    required this.trash,
    required this.code,
    required this.message,
  });

  factory FolderResponse.fromJson(Map<String, dynamic> json) {
    final dynamic rawData = json['data'];
    List<FolderModel> activeList = [];
    List<FolderModel> trashList = [];

    List<FolderModel> parse(dynamic raw) => (raw is List ? raw : const [])
        .whereType<Map>()
        .map((e) => FolderModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    if (rawData is Map) {
      final all = [...parse(rawData['folder']), ...parse(rawData['archive'])];
      activeList = all.where((f) => f.deletedAt == null).toList();
      trashList = [
        ...parse(rawData['trash']),
        ...all.where((f) => f.deletedAt != null),
      ];
    } else if (rawData is List) {
      final all = parse(rawData);
      activeList = all.where((f) => f.deletedAt == null).toList();
      trashList = all.where((f) => f.deletedAt != null).toList();
    }

    return FolderResponse(
      folders: activeList,
      trash: trashList,
      code: asInt(json['code']),
      message: asString(json['message']),
    );
  }
}
