import '../../domain/entities/note.dart';

class NoteModel extends Note {
  static const _notProvided = Object();

  const NoteModel({
    super.id,
    required super.title,
    required super.content,
    required super.createdAt,
    required super.updatedAt,
    super.isDeleted,
    super.deletedAt,
    super.imagePaths,
    super.folderId,
    super.isPinned,
    super.isLocked,
  });

  factory NoteModel.fromMap(Map<String, Object?> map) {
    return NoteModel(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      imagePaths:
          (map['image_paths'] as String?)
              ?.split('|')
              .where((e) => e.isNotEmpty)
              .toList() ??
          [],
      folderId: map['folder_id'] as int?,
      isPinned: (map['is_pinned'] as int? ?? 0) == 1,
      isLocked: (map['is_locked'] as int? ?? 0) == 1,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'is_deleted': isDeleted ? 1 : 0,
      'deleted_at': deletedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'image_paths': imagePaths.join('|'),
      'folder_id': folderId,
      'is_pinned': isPinned ? 1 : 0,
      'is_locked': isLocked ? 1 : 0,
    };
  }

  NoteModel copyWith({
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
    return NoteModel(
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

  factory NoteModel.fromEntity(Note note) {
    return NoteModel(
      id: note.id,
      title: note.title,
      content: note.content,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
      isDeleted: note.isDeleted,
      deletedAt: note.deletedAt,
      imagePaths: note.imagePaths,
      folderId: note.folderId,
      isPinned: note.isPinned,
      isLocked: note.isLocked,
    );
  }
}
