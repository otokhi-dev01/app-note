import 'package:get/get.dart';
import '../../../notes/presentation/controllers/home_controller.dart';
import '../controller/recently_deleted_folders_controller.dart';

class RecentlyDeletedFoldersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RecentlyDeletedFoldersController>(
      () => RecentlyDeletedFoldersController(
        homeController: Get.find<HomeController>(),
      ),
    );
  }
}
