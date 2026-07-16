import 'package:get/get.dart';
import '../../core/database/database_service.dart';
import '../../domain/repositories/note_repository.dart';
import '../../data/repositories/note_repository_impl.dart';
import '../../data/services/local_storage.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/folder_api_service.dart';
import '../../data/services/note_api_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<DatabaseService>(DatabaseService(), permanent: true);
    Get.put<LocalStorage>(LocalStorage(), permanent: true);
    Get.put<AuthService>(
      AuthService(Get.find<LocalStorage>()),
      permanent: true,
    );
    Get.put<FolderApiService>(
      FolderApiService(Get.find<AuthService>()),
      permanent: true,
    );
    Get.put<NoteApiService>(
      NoteApiService(Get.find<AuthService>()),
      permanent: true,
    );

    Get.lazyPut<NoteRepository>(
      () => NoteRepositoryImpl(
        Get.find<DatabaseService>(),
        Get.find<AuthService>(),
        Get.find<FolderApiService>(),
        Get.find<NoteApiService>(),
      ),
      fenix: true,
    );
  }
}
