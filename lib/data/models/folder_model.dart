class FolderModel {
  final int? id;
  final String name;
  final String? iconName;
  final String? colorValue;
  final int? sortOrder;
  final int? noteCount;

  FolderModel({
    this.id,
    required this.name,
    this.iconName,
    this.colorValue,
    this.sortOrder,
    this.noteCount,
  });

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    return FolderModel(
      id: json['id'] ?? json['Id'],
      name: json['name'] ?? json['Name'] ?? '',
      iconName: json['iconName'] ?? json['IconName'],
      colorValue: json['colorValue'] ?? json['ColorValue'],
      sortOrder: json['sortOrder'] ?? json['SortOrder'],
      noteCount: json['noteCount'] ?? json['NoteCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'folderId': id ?? 0,
      'name': name,
      'iconName': iconName,
      'colorValue': colorValue,
      'sortOrder': sortOrder,
    };
  }
}
