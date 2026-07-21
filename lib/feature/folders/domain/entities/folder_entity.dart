class FolderEntity {
  final int id;
  final String userId;
  final String name;
  final String iconName;
  final String colorValue;
  final int sortOrder;
  final int noteCount;
  final bool isInTrash;

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

  bool get isDeleted {
    return isInTrash || deletedAt != null;
  }

  factory FolderEntity.fromJson(Map<String, dynamic> json) {
    return FolderEntity(
      id: _toInt(
        _readValue(json, const <String>['FolderId', 'folderId', 'Id', 'id']),
      ),
      userId:
          _readValue(json, const <String>['UserId', 'userId'])?.toString() ??
          '',
      name:
          _readValue(json, const <String>[
            'FolderName',
            'folderName',
            'Name',
            'name',
          ])?.toString() ??
          '',
      iconName:
          _readValue(json, const <String>[
            'IconName',
            'iconName',
          ])?.toString() ??
          'folder',
      colorValue:
          _readValue(json, const <String>[
            'ColorValue',
            'colorValue',
          ])?.toString() ??
          '#2196F3',
      sortOrder: _toInt(
        _readValue(json, const <String>['SortOrder', 'sortOrder']),
      ),
      noteCount: _toInt(
        _readValue(json, const <String>['NoteCount', 'noteCount']),
      ),
      isInTrash:
          _toBool(_readValue(json, const <String>['IsInTrash', 'isInTrash'])) ||
          _toBool(_readValue(json, const <String>['IsDeleted', 'isDeleted'])),
      createdAt: _toDateTime(
        _readValue(json, const <String>['CreatedAt', 'createdAt']),
      ),
      updatedAt: _toDateTime(
        _readValue(json, const <String>['UpdatedAt', 'updatedAt']),
      ),
      deletedAt: _toDateTime(
        _readValue(json, const <String>['DeletedAt', 'deletedAt']),
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
      deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
    );
  }

  static dynamic _readValue(Map<String, dynamic> json, List<String> keys) {
    for (final String key in keys) {
      if (json.containsKey(key)) {
        return json[key];
      }
    }

    for (final MapEntry<String, dynamic> entry in json.entries) {
      final String currentKey = entry.key.toLowerCase();

      for (final String key in keys) {
        if (currentKey == key.toLowerCase()) {
          return entry.value;
        }
      }
    }

    return null;
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString().trim() ?? '') ?? 0;
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

    if (value is DateTime) {
      return value;
    }

    final String text = value.toString().trim();

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }

    return DateTime.tryParse(text);
  }
}
