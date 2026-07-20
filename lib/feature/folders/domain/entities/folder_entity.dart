class FolderEntity {
  final int id;
  final String userId;
  final String name;
  final String iconName;
  final String colorValue;
  final int sortOrder;
  final int noteCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const FolderEntity({
    required this.id,
    this.userId = '',
    required this.name,
    this.iconName = 'folder',
    this.colorValue = '#2196F3',
    this.sortOrder = 0,
    this.noteCount = 0,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  factory FolderEntity.fromJson(
      Map<String, dynamic> json,
      ) {
    return FolderEntity(
      id: _toInt(
        json['FolderId'] ??
            json['folderId'] ??
            json['Id'] ??
            json['id'],
      ),
      userId:
      json['UserId']?.toString() ??
          json['userId']?.toString() ??
          '',
      name:
      json['FolderName']?.toString() ??
          json['folderName']?.toString() ??
          json['Name']?.toString() ??
          json['name']?.toString() ??
          '',
      iconName:
      json['IconName']?.toString() ??
          json['iconName']?.toString() ??
          'folder',
      colorValue:
      json['ColorValue']?.toString() ??
          json['colorValue']?.toString() ??
          '#2196F3',
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

  FolderEntity copyWith({
    int? id,
    String? userId,
    String? name,
    String? iconName,
    String? colorValue,
    int? sortOrder,
    int? noteCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return FolderEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      colorValue: colorValue ?? this.colorValue,
      sortOrder: sortOrder ?? this.sortOrder,
      noteCount: noteCount ?? this.noteCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt:
      clearDeletedAt
          ? null
          : deletedAt ?? this.deletedAt,
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    final String text = value.toString().trim();

    if (text.isEmpty ||
        text.toLowerCase() == 'null') {
      return null;
    }

    return DateTime.tryParse(text);
  }
}
