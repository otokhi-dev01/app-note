import '../../domain/entities/folder.dart';

class FolderModel extends Folder {
  const FolderModel({
    super.id,
    required super.name,
    required super.createdAt,
  });

  factory FolderModel.fromMap(Map<String, Object?> map) {
    return FolderModel(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  FolderModel copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
  }) {
    return FolderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
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
