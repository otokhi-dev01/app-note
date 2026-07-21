import 'package:get/get.dart';

import '../../../folders/domain/entities/folder_entity.dart';
import '../../../notes/domain/entities/note_entity.dart';
import '../../../notes/presentation/controllers/home_controller.dart';

class RecycleBinController extends GetxController {
  final HomeController homeController;

  RecycleBinController({required this.homeController});

  final RxBool isRefreshing = false.obs;
  final RxnInt restoringFolderId = RxnInt();
  final RxnInt restoringNoteId = RxnInt();
  final RxString errorMessage = ''.obs;

  List<FolderEntity> get deletedFolders {
    final List<FolderEntity> result = homeController.deletedFolders.toList(
      growable: false,
    );

    result.sort((FolderEntity first, FolderEntity second) {
      final DateTime firstDate =
          first.deletedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime secondDate =
          second.deletedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      return secondDate.compareTo(firstDate);
    });

    return result;
  }

  List<NoteEntity> get archivedNotes {
    return homeController.notes
        .where((NoteEntity note) {
          return note.isArchived;
        })
        .toList(growable: false);
  }

  bool get isEmpty {
    return deletedFolders.isEmpty && archivedNotes.isEmpty;
  }

  bool isRestoringFolder(int folderId) {
    return restoringFolderId.value == folderId;
  }

  bool isRestoringNote(int noteId) {
    return restoringNoteId.value == noteId;
  }

  @override
  void onInit() {
    super.onInit();
    refreshData();
  }

  Future<void> refreshData() async {
    if (isRefreshing.value) {
      return;
    }

    try {
      isRefreshing.value = true;
      errorMessage.value = '';

      // HomeController owns the optimistic delete/restore reconciliation. Both
      // recycle-bin screens must refresh and read that same state so a stale
      // GET cannot erase a folder that the delete API already confirmed.
      await Future.wait<void>(<Future<void>>[
        homeController.loadFolders(),
        homeController.loadNotes(),
      ]);

      errorMessage.value = _refreshErrorMessage();
    } catch (error) {
      errorMessage.value = _cleanError(error);
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> restoreFolder(FolderEntity folder) async {
    if (folder.id <= 0 || restoringFolderId.value != null) {
      return;
    }

    try {
      restoringFolderId.value = folder.id;
      errorMessage.value = '';

      final bool restored = await homeController.deleteOrRestoreFolder(
        folderId: folder.id,
        isDelete: false,
      );

      if (!restored) {
        final String message = homeController.folderErrorMessage.value.trim();
        errorMessage.value = message.isEmpty
            ? 'The folder could not be restored. Please try again.'
            : message;
      }
    } catch (error) {
      errorMessage.value = _cleanError(error);
    } finally {
      restoringFolderId.value = null;
    }
  }

  Future<void> restoreNote(NoteEntity note) async {
    if (note.id <= 0 || restoringNoteId.value != null) {
      return;
    }

    try {
      restoringNoteId.value = note.id;
      errorMessage.value = '';

      final bool restored = await homeController.restoreArchivedNote(note);

      if (!restored) {
        final String message = homeController.noteErrorMessage.value.trim();
        errorMessage.value = message.isEmpty
            ? 'The note could not be restored. Please try again.'
            : message;
      }
    } catch (error) {
      errorMessage.value = _cleanError(error);
    } finally {
      restoringNoteId.value = null;
    }
  }

  String _refreshErrorMessage() {
    final List<String> messages = <String>[
      homeController.folderErrorMessage.value.trim(),
      homeController.noteErrorMessage.value.trim(),
    ].where((String message) => message.isNotEmpty).toSet().toList();

    return messages.join('\n');
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('ApiException: ', '')
        .replaceFirst('Exception: ', '')
        .trim();
  }
}
