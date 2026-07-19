class FolderEntity {
  final int id;
  final String userId;
  final String name;
  final String iconName;
  final String colorValue;
  final int sortOrder;
  final int noteCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const FolderEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.iconName,
    required this.colorValue,
    required this.sortOrder,
    required this.noteCount,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });
}