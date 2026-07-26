class ContentBlockModel {
  final String id;
  final String type; // text, checklist, attachment
  final String? text;
  final int? attachmentId;
  final String? displayName;
  final List<ChecklistItemModel>? items;

  ContentBlockModel({
    required this.id,
    required this.type,
    this.text,
    this.attachmentId,
    this.displayName,
    this.items,
  });

  factory ContentBlockModel.fromJson(Map<String, dynamic> json) {
    return ContentBlockModel(
      id: json['Id'] ?? json['id'],
      type: json['Type'] ?? json['type'],
      text: json['Text'] ?? json['text'],
      attachmentId: json['AttachmentId'] ?? json['attachmentId'],
      displayName: json['DisplayName'] ?? json['displayName'],
      items: (json['Items'] as List?)?.map((e) => ChecklistItemModel.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'text': text,
      'attachmentId': attachmentId,
      'displayName': displayName,
      'items': items?.map((e) => e.toJson()).toList(),
    };
  }
}

class ChecklistItemModel {
  final String id;
  final String text;
  final bool checked;

  ChecklistItemModel({
    required this.id,
    required this.text,
    required this.checked,
  });

  factory ChecklistItemModel.fromJson(Map<String, dynamic> json) {
    return ChecklistItemModel(
      id: json['Id'] ?? json['id'],
      text: json['Text'] ?? json['text'] ?? '',
      checked: json['Checked'] ?? json['checked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'checked': checked,
    };
  }
}
