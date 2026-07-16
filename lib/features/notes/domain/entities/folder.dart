class Folder {
  const Folder({this.id, required this.name, required this.createdAt});

  final int? id;
  final String name;
  final DateTime createdAt;

  Folder copyWith({int? id, String? name, DateTime? createdAt}) {
    return Folder(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
