import '../../domain/entities/folder.dart';

class FolderModel extends Folder {
  const FolderModel({
    super.id,
    required super.name,
    required super.createdAt,
    this.isDeleted = false,
  });

  final bool isDeleted;

  factory FolderModel.fromMap(Map<String, Object?> map) {
    final rawDeleted =
        map['is_deleted'] ??
        map['isDeleted'] ??
        map['deleted'] ??
        map['IsDeleted'] ??
        map['Deleted'];
    final isDeleted = rawDeleted is int
        ? rawDeleted != 0
        : rawDeleted is String
        ? rawDeleted.toLowerCase() == 'true' || rawDeleted == '1'
        : false;
    return FolderModel(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      isDeleted: isDeleted,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  @override
  FolderModel copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    bool? isDeleted,
  }) {
    return FolderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  factory FolderModel.fromEntity(Folder folder) {
    return FolderModel(
      id: folder.id,
      name: folder.name,
      createdAt: folder.createdAt,
    );
  }
}
