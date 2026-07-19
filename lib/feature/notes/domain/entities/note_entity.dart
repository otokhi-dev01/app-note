// class NoteEntity {
//   final int id;
//   final int folderId;
//   final String title;
//   final List<Map<String, dynamic>> content;
//   final bool isPinned;
//   final bool isArchived;
//   final bool isLocked;
//
//   const NoteEntity({
//     required this.id,
//     required this.folderId,
//     required this.title,
//     required this.content,
//     required this.isPinned,
//     required this.isArchived,
//     required this.isLocked,
//   });
// }

class NoteEntity {
  final int id;
  final int folderId;
  final String title;
  final List<Map<String, dynamic>> content;
  final bool isPinned;
  final bool isArchived;
  final bool isLocked;

  const NoteEntity({
    required this.id,
    required this.folderId,
    required this.title,
    required this.content,
    required this.isPinned,
    required this.isArchived,
    required this.isLocked,
  });
}