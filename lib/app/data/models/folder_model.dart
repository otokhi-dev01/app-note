import 'package:flutter/material.dart';

class FolderModel {
  final int id;
  final String name;
  final String iconName;
  final String colorValue;
  final int sortOrder;
  final int noteCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FolderModel({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorValue,
    required this.sortOrder,
    this.noteCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    return FolderModel(
      id: json['FolderId'] ?? json['id'] ?? json['Id'] ?? 0,
      name: (json['FolderName'] ?? json['Name'] ?? json['name'] ?? '').toString().trim(),
      iconName: json['IconName'] ?? json['iconName'] ?? '',
      colorValue: json['ColorValue'] ?? json['colorValue'] ?? '',
      sortOrder: json['SortOrder'] ?? json['sortOrder'] ?? 0,
      noteCount: json['NoteCount'] ?? json['noteCount'] ?? 0,
      createdAt: json['CreatedAt'] != null ? DateTime.tryParse(json['CreatedAt']) : null,
      updatedAt: json['UpdatedAt'] != null ? DateTime.tryParse(json['UpdatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "FolderId": id,
    "FolderName": name,
    "Name": name, 
    "name": name,
    "IconName": iconName,
    "iconName": iconName,
    "ColorValue": colorValue,
    "colorValue": colorValue,
    "SortOrder": sortOrder,
    "sortOrder": sortOrder,
  };

  IconData get icon {
    switch (iconName.toLowerCase()) {
      case 'work': return Icons.work_outline;
      case 'school': return Icons.school_outlined;
      case 'favorite': return Icons.favorite_border;
      case '5': return Icons.code_rounded;
      case 'folder': return Icons.folder_open_rounded;
      default: return Icons.folder_open_rounded;
    }
  }

  Color get color {
    if (colorValue.isEmpty) return const Color(0xFFFF69B4);
    if (colorValue.startsWith('#')) {
      return Color(int.parse(colorValue.replaceFirst('#', '0xFF')));
    }
    // Handle large decimal strings from API
    return Color(int.tryParse(colorValue) ?? 0xFFFF69B4);
  }
}

class FolderResponse {
  final List<FolderModel> folders;
  final List<dynamic> trash;
  final int code;
  final String message;

  FolderResponse({
    required this.folders,
    required this.trash,
    required this.code,
    required this.message,
  });

  factory FolderResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final List folderList = data['folder'] as List? ?? [];
    final List archiveList = data['archive'] as List? ?? [];
    final List trashList = data['trash'] as List? ?? [];
    
    // Combine folder and archive for active display
    final List combinedFolders = [...folderList, ...archiveList];

    return FolderResponse(
      folders: combinedFolders
          .map((e) => FolderModel.fromJson(e))
          .toList(),
      trash: trashList,
      code: json['code'] ?? 0,
      message: json['message'] ?? '',
    );
  }
}
