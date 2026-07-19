import 'package:get/get.dart';
import '../../domain/repositories/note_repository.dart';
import '../controllers/home_controller.dart';
import '../controllers/note_editor_controller.dart';

class NoteEditorBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NoteEditorController>(
          () => NoteEditorController(
        noteRepository:
        Get.find<NoteRepository>(),
        homeController:
        Get.isRegistered<HomeController>()
            ? Get.find<HomeController>()
            : null,
      ),
    );
  }
}