import 'package:get/get.dart';
import '../../../data/providers/folder_service.dart';
import '../../../data/providers/note_service.dart';
import '../controllers/note_controller.dart';
import '../controllers/note_detail_controller.dart';

class NoteBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => NoteController());
    Get.lazyPut(() => NoteDetailController(
          noteService: Get.find<NoteService>(),
          folderService: Get.find<FolderService>(),
        ), fenix: true);
  }
}
