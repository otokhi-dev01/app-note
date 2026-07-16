import 'package:get/get.dart';
import 'package:notes/features/auth/domain/repositories/auth_repository.dart';
import 'package:notes/features/library/application/library_coordinator.dart';
import 'package:notes/features/notes/domain/repositories/note_repository.dart';
import 'package:notes/features/notes/domain/repositories/attachment_file_repository.dart';
import 'package:notes/features/notes/domain/usecases/delete_note_usecase.dart';
import 'package:notes/features/notes/domain/usecases/get_notes_usecase.dart';
import 'package:notes/features/notes/domain/usecases/update_note_usecase.dart';
import 'package:notes/features/search/domain/repositories/recent_search_repository.dart';
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
        repository: repository,
        authRepository: Get.find<AuthRepository>(),
        recentSearchRepository: Get.find<RecentSearchRepository>(),
        attachmentFiles: Get.find<AttachmentFileRepository>(),
      ),
    );
    Get.lazyPut<LibraryCoordinator>(() => Get.find<HomeController>());
  }
}
