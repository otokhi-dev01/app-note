import 'package:get/get.dart';

import 'package:Note/features/folder/domain/usecases/folder_usecases.dart';
import 'package:Note/features/folder/presentation/controllers/folder_controller.dart';
import 'package:Note/features/note/domain/usecases/note_usecases.dart';

class FolderBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(
      FolderController(
        getFolders: Get.find<GetFolders>(),
        saveFolder: Get.find<SaveFolder>(),
        deleteRestoreFolder: Get.find<DeleteRestoreFolder>(),
        buildHierarchy: Get.find<BuildFolderHierarchy>(),
        getNotes: Get.find<GetNotes>(),
      ),
    );
  }
}
