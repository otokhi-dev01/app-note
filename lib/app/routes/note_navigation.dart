import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../data/models/note_model.dart';
import 'app_pages.dart';

class NoteNavigation {
  static Future<T?>? toDetail<T>(NoteModel note) {
    if (note.id <= 0) {
      if (kDebugMode) {
        debugPrint("[NOTE NAVIGATION ERROR] Attempted to open note with invalid ID: ${note.id}");
        debugPrint("Title: ${note.title}, FolderId: ${note.folderId}");
      }
      Get.snackbar("Error", "Invalid Note ID");
      return null;
    }

    final isDeleted = note.deletedAt != null;

    if (kDebugMode) {
      debugPrint("[NOTE NAVIGATION] Opening Note");
      debugPrint("Title: ${note.title}");
      debugPrint("NoteId: ${note.id}");
      debugPrint("FolderId: ${note.folderId}");
      debugPrint("IsArchived: ${note.isArchived}");
      debugPrint("IsDeleted: $isDeleted");
    }

    return Get.toNamed(
      Routes.NOTE_DETAIL,
      arguments: {
        "noteId": note.id,
        "folderId": note.folderId,
        "isArchived": note.isArchived,
        "isDeleted": isDeleted,
      },
    );
  }

  static Future<T?>? toNewNote<T>(int folderId) {
    if (kDebugMode) {
      debugPrint("[NOTE NAVIGATION] Creating New Note in Folder: $folderId");
    }
    return Get.toNamed(
      Routes.NOTE_DETAIL,
      arguments: {
        "noteId": 0,
        "folderId": folderId,
        "isArchived": false,
        "isDeleted": false,
      },
    );
  }
}
