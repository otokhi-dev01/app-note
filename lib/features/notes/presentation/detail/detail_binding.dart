import 'package:get/get.dart';
import 'package:notes/features/notes/domain/repositories/note_repository.dart';
import 'package:notes/features/notes/domain/repositories/attachment_file_repository.dart';
import 'package:notes/features/notes/domain/usecases/get_note_usecase.dart';
import 'package:notes/features/notes/domain/usecases/update_note_usecase.dart';
import 'detail_controller.dart';

class DetailBinding extends Bindings {
  @override
  void dependencies() {
    final repository = Get.find<NoteRepository>();

    Get.lazyPut(() => GetNoteUseCase(repository));
    Get.lazyPut(() => UpdateNoteUseCase(repository));

    Get.lazyPut<DetailController>(
      () => DetailController(
        Get.find<GetNoteUseCase>(),
        Get.find<UpdateNoteUseCase>(),
        attachmentFiles: Get.find<AttachmentFileRepository>(),
      ),
    );
  }
}
