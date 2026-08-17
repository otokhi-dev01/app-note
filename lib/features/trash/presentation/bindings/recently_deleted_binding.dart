import 'package:get/get.dart';

import 'package:Note/features/folder/domain/usecases/folder_usecases.dart';
import 'package:Note/features/note/domain/usecases/note_usecases.dart';
import 'package:Note/features/trash/presentation/controllers/recently_deleted_controller.dart';

class RecentlyDeletedBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => RecentlyDeletedController(
        getTrashNotes: Get.find<GetTrashNotes>(),
        getFolders: Get.find<GetFolders>(),
        deleteRestoreNote: Get.find<DeleteRestoreNote>(),
        deleteRestoreFolder: Get.find<DeleteRestoreFolder>(),
        deleteNotePermanently: Get.find<DeleteNotePermanently>(),
        emptyTrash: Get.find<EmptyTrash>(),
      ),
    );
  }
}
