import 'package:get/get.dart';
import 'package:notes/domain/repositories/note_repository.dart';
import 'package:notes/domain/usecases/create_note_usecase.dart';
import 'package:notes/domain/usecases/update_note_usecase.dart';
import 'editor_controller.dart';

class EditorBinding extends Bindings {
  @override
  void dependencies() {
    final repository = Get.find<NoteRepository>();
    Get.lazyPut(() => CreateNoteUseCase(repository));
    Get.lazyPut(() => UpdateNoteUseCase(repository));
    Get.lazyPut<EditorController>(
      () => EditorController(
        Get.find<CreateNoteUseCase>(),
        Get.find<UpdateNoteUseCase>(),
      ),
    );
  }
}
