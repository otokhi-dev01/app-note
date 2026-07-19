import 'package:get/get.dart';
import '../../../folders/domain/entities/folder_entity.dart';
import '../../../notes/domain/entities/note_entity.dart';
import '../../../notes/presentation/controllers/home_controller.dart';

class RecycleBinController
    extends GetxController {
  final HomeController homeController;

  RecycleBinController({
    required this.homeController,
  });

  final RxBool isRefreshing = false.obs;

  List<FolderEntity> get deletedFolders {
    return homeController.deletedFolders;
  }

  List<NoteEntity> get archivedNotes {
    return homeController.archivedNotes;
  }

  bool get isEmpty {
    return deletedFolders.isEmpty &&
        archivedNotes.isEmpty;
  }

  Future<void> refreshData() async {
    try {
      isRefreshing.value = true;

      await homeController.loadAll();
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> restoreFolder(
      FolderEntity folder,
      ) async {
    await homeController.deleteOrRestoreFolder(
      folderId: folder.id,
      isDelete: false,
    );
  }

  Future<void> restoreNote(
      NoteEntity note,
      ) async {
    await homeController.archiveNote(note);
  }
}