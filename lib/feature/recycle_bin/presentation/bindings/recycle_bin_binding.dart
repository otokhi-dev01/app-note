import 'package:get/get.dart';
import '../../../folders/domain/repositories/folder_repository.dart';
import '../../../notes/domain/repositories/note_repository.dart';
import '../controllers/recycle_bin_controller.dart';

class RecycleBinBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RecycleBinController>(
          () => RecycleBinController(
        folderRepository: Get.find<FolderRepository>(),
        noteRepository: Get.find<NoteRepository>(), homeController: Get.find(),
      ),
    );
  }
}
