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
}
