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
}
