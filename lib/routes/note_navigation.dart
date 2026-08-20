import 'package:get/get.dart';

import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/features/note/domain/entities/note.dart';
import 'package:Note/routes/app_pages.dart';

/// Typed entry points into the note editor.
///
/// Centralized so every caller passes the same argument map — the editor reads
/// `noteId`, `folderId`, `isArchived` and `isDeleted` out of it.
class NoteNavigation {
  NoteNavigation._();

  static Future<T?>? toDetail<T>(Note note) {
    if (note.id <= 0) {
      AppSnackbar.error('Cannot open note', 'This note has an invalid ID.');
      return null;
    }

    return Get.toNamed(
      Routes.NOTE_DETAIL,
      arguments: {
        'noteId': note.id,
        'folderId': note.folderId,
        'isArchived': note.isArchived,
        'isDeleted': note.isDeleted,
        // The full note travels along so a deleted note can still render
        // without a detail fetch that would 404.
        'note': note,
        'instanceTag': _newInstanceTag(),
      },
      // Every entry point shares the same route name (Routes.NOTE_DETAIL),
      // so opening one note from within another would otherwise collide
      // with GetX's `preventDuplicates` (on by default) and silently no-op.
      preventDuplicates: false,
    );
  }

  static Future<T?>? toNewNote<T>(int folderId) => Get.toNamed(
    Routes.NOTE_DETAIL,
    arguments: {
      'noteId': 0,
      'folderId': folderId,
      'isArchived': false,
      'isDeleted': false,
      'instanceTag': _newInstanceTag(),
    },
    preventDuplicates: false,
  );

  // NoteBinding registers NoteDetailController under this tag (see
  // note_binding.dart) so every push gets its own instance. Without it, opening
  // a note — or starting a new one — from inside an already-open note would
  // hand back that note's still-alive singleton controller instead of a fresh
  // one, so the "new" page would just keep showing whatever was underneath it.
  static String _newInstanceTag() =>
      'note_${DateTime.now().microsecondsSinceEpoch}';
}
