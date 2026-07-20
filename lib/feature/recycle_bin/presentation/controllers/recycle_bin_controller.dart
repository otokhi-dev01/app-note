import 'package:get/get.dart';
import 'package:note_app/feature/notes/presentation/controllers/home_controller.dart';
import '../../../folders/domain/entities/folder_entity.dart';
import '../../../folders/domain/repositories/folder_repository.dart';
import '../../../notes/domain/entities/note_entity.dart';
import '../../../notes/domain/repositories/note_repository.dart';


class RecycleBinController extends GetxController {
  final FolderRepository folderRepository;
  final NoteRepository noteRepository;

  RecycleBinController({
    required this.folderRepository,
    required this.noteRepository, required HomeController homeController,
  });

  final RxList<FolderEntity> deletedFolders =
      <FolderEntity>[].obs;

  final RxList<NoteEntity> archivedNotes =
      <NoteEntity>[].obs;

  final RxBool isRefreshing = false.obs;
  final RxString errorMessage = ''.obs;

  bool get isEmpty {
    return deletedFolders.isEmpty &&
        archivedNotes.isEmpty;
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

      final List<FolderEntity> allFolders =
      await folderRepository.getFolders();

      final List<NoteEntity> allNotes =
      await noteRepository.getNotes();

      final List<FolderEntity> deleted =
      allFolders.where((FolderEntity folder) {
        return folder.isDeleted;
      }).toList();

      deleted.sort((
          FolderEntity first,
          FolderEntity second,
          ) {
        final DateTime firstDate =
            first.deletedAt ??
                DateTime.fromMillisecondsSinceEpoch(0);

        final DateTime secondDate =
            second.deletedAt ??
                DateTime.fromMillisecondsSinceEpoch(0);

        return secondDate.compareTo(firstDate);
      });

      final List<NoteEntity> archived =
      allNotes.where((NoteEntity note) {
        return note.isArchived;
      }).toList();

      deletedFolders.assignAll(deleted);
      archivedNotes.assignAll(archived);
    } catch (error) {
      errorMessage.value = _cleanError(error);
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> restoreFolder(
      FolderEntity folder,
      ) async {
    try {
      await folderRepository.deleteOrRestoreFolder(
        id: folder.id,
        isDelete: false,
      );

      deletedFolders.removeWhere(
            (FolderEntity item) => item.id == folder.id,
      );

      await refreshData();

      Get.snackbar(
        'Folder restored',
        '${_folderName(folder)} was restored successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar(
        'Restore failed',
        _cleanError(error),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> restoreNote(
      NoteEntity note,
      ) async {
    try {
      await noteRepository.updateState(
        noteId: note.id,
        isPinned: note.isPinned,
        isArchived: false,
        isLocked: note.isLocked,
      );

      archivedNotes.removeWhere(
            (NoteEntity item) => item.id == note.id,
      );

      await refreshData();

      Get.snackbar(
        'Note restored',
        'The note was removed from the archive.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      Get.snackbar(
        'Restore failed',
        _cleanError(error),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  String _folderName(FolderEntity folder) {
    final String name = folder.name.trim();

    return name.isEmpty ? 'The folder' : name;
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('ApiException: ', '')
        .replaceFirst('Exception: ', '')
        .trim();
  }
}