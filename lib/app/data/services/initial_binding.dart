import 'package:get/get.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'folder_service.dart';
import 'note_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ApiService(), permanent: true);
    Get.lazyPut(() => AuthService(), fenix: true);
    Get.lazyPut(() => FolderService(), fenix: true);
    Get.lazyPut(() => NoteService(), fenix: true);
  }
}
