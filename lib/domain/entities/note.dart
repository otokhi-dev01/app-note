class Note {
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
}
