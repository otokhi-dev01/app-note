import 'package:get/get.dart';
import '../../../notes/presentation/controllers/home_controller.dart';
import '../controller/create_folder_controller.dart';

class CreateFolderBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreateFolderController>(
          () => CreateFolderController(
        homeController:
        Get.find<HomeController>(),
      ),
    );
  }
}