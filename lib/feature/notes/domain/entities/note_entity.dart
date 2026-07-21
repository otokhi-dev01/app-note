class NoteEntity {
  final int id;
  final int folderId;
  final String folderName;
  final String title;
  final List<Map<String, dynamic>> content;
  final bool isPinned;
  final bool isArchived;
  final bool isLocked;
  final bool isInTrash;
  final int sortOrder;
  final int attachmentCount;
  final DateTime? pinnedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const NoteEntity({
    required this.id,
    required this.folderId,
    this.folderName = '',
    required this.title,
    required this.content,
    required this.isPinned,
    required this.isArchived,
    required this.isLocked,
    this.isInTrash = false,
    this.sortOrder = 0,
    this.attachmentCount = 0,
    this.pinnedAt,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted {
    return isInTrash || deletedAt != null;
  }

  NoteEntity copyWith({
    int? id,
    int? folderId,
    String? folderName,
    String? title,
    List<Map<String, dynamic>>? content,
    bool? isPinned,
    bool? isArchived,
    bool? isLocked,
    bool? isInTrash,
    int? sortOrder,
    int? attachmentCount,
    DateTime? pinnedAt,
    bool clearPinnedAt = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return NoteEntity(
      id: id ?? this.id,
      folderId: folderId ?? this.folderId,
      folderName: folderName ?? this.folderName,
      title: title ?? this.title,
      content: content ?? this.content,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isLocked: isLocked ?? this.isLocked,
      isInTrash: isInTrash ?? this.isInTrash,
      sortOrder: sortOrder ?? this.sortOrder,
      attachmentCount: attachmentCount ?? this.attachmentCount,
      pinnedAt: clearPinnedAt ? null : pinnedAt ?? this.pinnedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
    );
  }
}
