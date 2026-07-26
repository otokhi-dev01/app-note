import 'content_block_model.dart';
import 'attachment_model.dart';

class NoteModel {
  final int? id;
  final int? folderId;
  final String? folderName;
  final String title;
  final bool isPinned;
  final bool isArchived;
  final bool isLocked;
  final int? sortOrder;
  final DateTime? pinnedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final int attachmentCount;
  final List<ContentBlockModel>? content;
  final List<AttachmentModel>? attachments;

  NoteModel({
    this.id,
    this.folderId,
    this.folderName,
    required this.title,
    this.isPinned = false,
    this.isArchived = false,
    this.isLocked = false,
    this.sortOrder,
    this.pinnedAt,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.attachmentCount = 0,
    this.content,
    this.attachments,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['NoteId'] ?? json['id'],
      folderId: json['FolderId'] ?? json['folderId'],
      folderName: json['FolderName'],
      title: json['Title'] ?? json['title'] ?? '',
      isPinned: json['IsPinned'] ?? json['isPinned'] ?? false,
      isArchived: json['IsArchived'] ?? json['isArchived'] ?? false,
      isLocked: json['IsLocked'] ?? json['isLocked'] ?? false,
      sortOrder: json['SortOrder'],
      pinnedAt: json['PinnedAt'] != null ? DateTime.parse(json['PinnedAt']) : null,
      createdAt: json['CreatedAt'] != null ? DateTime.parse(json['CreatedAt']) : null,
      updatedAt: json['UpdatedAt'] != null ? DateTime.parse(json['UpdatedAt']) : null,
      deletedAt: json['DeletedAt'] != null ? DateTime.parse(json['DeletedAt']) : null,
      attachmentCount: json['AttachmentCount'] ?? 0,
      content: (json['ContentJson'] as List?)?.map((e) => ContentBlockModel.fromJson(e)).toList(),
      attachments: (json['Attachments'] as List?)?.map((e) => AttachmentModel.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'noteId': id,
      'folderId': folderId,
      'title': title,
    };
  }
}
