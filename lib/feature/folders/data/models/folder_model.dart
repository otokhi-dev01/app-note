import '../../domain/entities/folder_entity.dart';

class FolderModel extends FolderEntity {
  const FolderModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.iconName,
    required super.colorValue,
    required super.sortOrder,
    required super.noteCount,
    super.createdAt,
    super.updatedAt,
    super.deletedAt,
  });

  factory FolderModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return FolderModel(
      id: _toInt(
        json['FolderId'] ??
            json['folderId'] ??
            json['Id'] ??
            json['id'],
      ),
      userId: _toString(
        json['UserId'] ??
            json['userId'],
      ),
      name: _toString(
        json['FolderName'] ??
            json['folderName'] ??
            json['Name'] ??
            json['name'],
      ),
      iconName: _toString(
        json['IconName'] ??
            json['iconName'],
      ),
      colorValue: _toString(
        json['ColorValue'] ??
            json['colorValue'],
      ),
      sortOrder: _toInt(
        json['SortOrder'] ??
            json['sortOrder'],
      ),
      noteCount: _toInt(
        json['NoteCount'] ??
            json['noteCount'],
      ),
      createdAt: _toDateTime(
        json['CreatedAt'] ??
            json['createdAt'],
      ),
      updatedAt: _toDateTime(
        json['UpdatedAt'] ??
            json['updatedAt'],
      ),
      deletedAt: _toDateTime(
        json['DeletedAt'] ??
            json['deletedAt'],
      ),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }

  static String _toString(dynamic value) {
    return value?.toString() ?? '';
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    final String rawValue = value.toString().trim();

    if (rawValue.isEmpty) {
      return null;
    }

    return DateTime.tryParse(rawValue);
  }
}