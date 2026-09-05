import 'package:get/get.dart';
import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/features/note/domain/entities/note.dart';
import 'package:Note/routes/app_pages.dart';

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

        'note': note,
        'instanceTag': _newInstanceTag(),
      },

      preventDuplicates: false,
    );
  }

  static Future<T?>? toNewNote<T>(
    int folderId, {
    bool autoRecord = false,
    bool autoAlbumPdf = false,
  }) => Get.toNamed(
    Routes.NOTE_DETAIL,
    arguments: {
      'noteId': 0,
      'folderId': folderId,
      'isArchived': false,
      'isDeleted': false,
      'autoRecord': autoRecord,
      'autoAlbumPdf': autoAlbumPdf,
      'instanceTag': _newInstanceTag(),
    },
    preventDuplicates: false,
  );

  static Future<T?>? toNewAudioNote<T>(int folderId) =>
      toNewNote<T>(folderId, autoRecord: true);

  /// Opens a brand-new note that immediately prompts the photo library and
  /// inserts whatever gets picked as one auto-converted PDF attachment — the
  /// "Albums" quick action's landing spot.
  static Future<T?>? toNewNoteFromAlbumPdf<T>(int folderId) =>
      toNewNote<T>(folderId, autoAlbumPdf: true);

  static String _newInstanceTag() =>
      'note_${DateTime.now().microsecondsSinceEpoch}';
}
