import 'package:get/get.dart';
import '../../../domain/repositories/note_repository.dart';
import '../../../domain/usecases/get_notes_usecase.dart';
import '../../../domain/usecases/update_note_usecase.dart';
import '../../../domain/usecases/delete_note_usecase.dart';
import 'home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    final repository = Get.find<NoteRepository>();
    
    Get.lazyPut(() => GetNotesUseCase(repository));
    Get.lazyPut(() => UpdateNoteUseCase(repository));
    Get.lazyPut(() => DeleteNoteUseCase(repository));

    Get.lazyPut<HomeController>(
      () => HomeController(
        Get.find<GetNotesUseCase>(),
        Get.find<UpdateNoteUseCase>(),
        Get.find<DeleteNoteUseCase>(),
      ),
    );
  }
}
