import 'package:get/get.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../folders/data/repositories/folder_repository_impl.dart';
import '../../../folders/domain/repositories/folder_repository.dart';
import '../../../main/presentation/controller/main_navigation_controller.dart';
import '../../domain/repositories/note_repository.dart';
import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<
        MainNavigationController>()) {
      Get.lazyPut<MainNavigationController>(
            () => MainNavigationController(),
        fenix: true,
      );
    }

    if (!Get.isRegistered<FolderRepository>()) {
      Get.put<FolderRepository>(
        FolderRepositoryImpl(
          apiClient: Get.find<ApiClient>(),
        ),
        permanent: true,
      );
    }

    if (!Get.isRegistered<HomeController>()) {
      Get.lazyPut<HomeController>(
            () => HomeController(
          folderRepository:
          Get.find<FolderRepository>(),
          noteRepository:
          Get.find<NoteRepository>(),
          authRepository:
          Get.find<AuthRepository>(),
        ),
        fenix: true,
      );
    }
  }
}