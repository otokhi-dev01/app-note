class FolderEntity {
  final int id;
  final String userId;
  final String name;
  final String iconName;
  final String colorValue;
  final int sortOrder;
  final int noteCount;
<<<<<<< HEAD
=======
  final bool isInTrash;

>>>>>>> nona_feature
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
    this.isInTrash = false,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

<<<<<<< HEAD
  bool get isDeleted => deletedAt != null;
=======
  bool get isDeleted {
    return isInTrash || deletedAt != null;
  }
>>>>>>> nona_feature

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
      isInTrash:
          _toBool(_readValue(json, const <String>['IsInTrash', 'isInTrash'])) ||
          _toBool(_readValue(json, const <String>['IsDeleted', 'isDeleted'])),
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
    bool? isInTrash,
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
      isInTrash: isInTrash ?? this.isInTrash,
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

  static bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final String text = value?.toString().trim().toLowerCase() ?? '';

    return text == 'true' || text == '1';
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
