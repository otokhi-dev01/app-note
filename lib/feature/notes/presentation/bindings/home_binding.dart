import 'package:get/get.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../folders/domain/repositories/folder_repository_impl.dart';
import '../../../main/presentation/controller/main_navigation_controller.dart';
import '../../domain/repositories/note_repository.dart';
import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(
          () => HomeController(
        folderRepository:
        Get.find<FolderRepository>(),
        noteRepository:
        Get.find<NoteRepository>(),
        authRepository:
        Get.find<AuthRepository>(),
      ),
    );

    Get.lazyPut<MainNavigationController>(
          () => MainNavigationController(),
    );
  }
}