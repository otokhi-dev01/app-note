import 'package:get/get.dart';
import '../../domain/repositories/note_repository.dart';
import '../controllers/create_note_controller.dart';
import '../controllers/home_controller.dart';

class CreateNoteBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreateNoteController>(
      () => CreateNoteController(
        noteRepository: Get.find<NoteRepository>(),
        homeController: Get.find<HomeController>(),
      ),
    );
  }
}
