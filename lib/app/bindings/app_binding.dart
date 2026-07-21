import 'package:get/get.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../../feature/auth/data/repositories/auth_repository_impl.dart';
import '../../feature/auth/domain/repositories/auth_repository.dart';
import '../../feature/folders/data/repositories/folder_repository_impl.dart';
import '../../feature/folders/domain/repositories/folder_repository.dart';
import '../../feature/notes/data/repositories/note_repository_impl.dart';
import '../../feature/notes/domain/repositories/note_repository.dart';
import '../../feature/notes/presentation/controllers/home_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<TokenStorage>(TokenStorage(), permanent: true);

    Get.put<ApiClient>(
      ApiClient(tokenStorage: Get.find<TokenStorage>()),
      permanent: true,
    );

    Get.put<AuthRepository>(
      AuthRepositoryImpl(
        apiClient: Get.find<ApiClient>(),
        tokenStorage: Get.find<TokenStorage>(),
      ),
      permanent: true,
    );

    Get.put<FolderRepository>(
      FolderRepositoryImpl(apiClient: Get.find<ApiClient>()),
      permanent: true,
    );

    Get.put<NoteRepository>(
      NoteRepositoryImpl(apiClient: Get.find<ApiClient>()),
      permanent: true,
    );

    Get.lazyPut<HomeController>(
      () => HomeController(
        folderRepository: Get.find<FolderRepository>(),
        noteRepository: Get.find<NoteRepository>(),
        authRepository: Get.find<AuthRepository>(),
      ),
      fenix: true,
    );
  }
}
