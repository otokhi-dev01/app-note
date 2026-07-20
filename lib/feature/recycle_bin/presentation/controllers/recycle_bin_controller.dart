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
  void onReady() {
    super.onReady();

    refreshData();
  }

  Future<void> refreshData() async {
    if (isRefreshing.value) {
      return;
    }

    try {
      isRefreshing.value = true;
      errorMessage.value = '';

      /*
       * Both calls read fresh data from the API.
       */
      await Future.wait<void>(<Future<void>>[
        homeController.loadFolders(),
        homeController.loadNotes(),
      ]);
    } catch (error) {
      errorMessage.value = _cleanError(error);
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> restoreFolder(FolderEntity folder) async {
    if (restoringFolderId.value != null) {
      return;
    }

    try {
      restoringFolderId.value = folder.id;

      errorMessage.value = '';

      await homeController.deleteOrRestoreFolder(
        folderId: folder.id,
        isDelete: false,
      );

      await homeController.loadFolders();
    } catch (error) {
      errorMessage.value = _cleanError(error);
    } finally {
      restoringFolderId.value = null;
    }
  }

  Future<void> restoreNote(NoteEntity note) async {
    if (restoringNoteId.value != null) {
      return;
    }

    try {
      restoringNoteId.value = note.id;

      errorMessage.value = '';

      await homeController.noteRepository.updateState(
        noteId: note.id,
        isPinned: note.isPinned,
        isArchived: false,
        isLocked: note.isLocked,
      );

      await homeController.loadNotes();

      Get.snackbar(
        'Note restored',
        'The note was removed from the archive.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      errorMessage.value = _cleanError(error);

      Get.snackbar(
        'Restore note failed',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      restoringNoteId.value = null;
    }
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('ApiException: ', '')
        .replaceFirst('StateError: ', '')
        .replaceFirst('Exception: ', '')
        .trim();
  }
}
