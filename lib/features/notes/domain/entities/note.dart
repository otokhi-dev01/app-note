class Note {
  static const _notProvided = Object();

  const Note({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.deletedAt,
    this.imagePaths = const [],
    this.folderId,
    this.isPinned = false,
    this.isLocked = false,
  });

  final int? id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final DateTime? deletedAt;
  final List<String> imagePaths;
  final int? folderId;
  final bool isPinned;
  final bool isLocked;

  Note copyWith({
    int? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    Object? deletedAt = _notProvided,
    List<String>? imagePaths,
    Object? folderId = _notProvided,
    bool? isPinned,
    bool? isLocked,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: identical(deletedAt, _notProvided)
          ? this.deletedAt
          : deletedAt as DateTime?,
      imagePaths: imagePaths ?? this.imagePaths,
      folderId: identical(folderId, _notProvided)
          ? this.folderId
          : folderId as int?,
      isPinned: isPinned ?? this.isPinned,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}
