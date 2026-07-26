class AttachmentModel {
  final int id;
  final int noteId;
  final String? blockId;
  final String originalFileName;
  final String storedFileName;
  final String filePath;
  final String attachmentType;
  final String mimeType;
  final int sizeBytes;
  final int displayOrder;
  final DateTime createdAt;

  AttachmentModel({
    required this.id,
    required this.noteId,
    this.blockId,
    required this.originalFileName,
    required this.storedFileName,
    required this.filePath,
    required this.attachmentType,
    required this.mimeType,
    required this.sizeBytes,
    required this.displayOrder,
    required this.createdAt,
  });

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      id: json['AttachmentId'] ?? json['id'],
      noteId: json['NoteId'] ?? json['noteId'],
      blockId: json['BlockId'],
      originalFileName: json['OriginalFileName'] ?? json['originalFileName'] ?? '',
      storedFileName: json['StoredFileName'] ?? json['storedFileName'] ?? '',
      filePath: json['FilePath'] ?? json['filePath'] ?? '',
      attachmentType: json['AttachmentType'] ?? json['attachmentType'] ?? '',
      mimeType: json['MimeType'] ?? json['mimeType'] ?? '',
      sizeBytes: json['SizeBytes'] ?? json['sizeBytes'] ?? 0,
      displayOrder: json['DisplayOrder'] ?? json['displayOrder'] ?? 0,
      createdAt: DateTime.parse(json['CreatedAt']),
    );
  }
}
