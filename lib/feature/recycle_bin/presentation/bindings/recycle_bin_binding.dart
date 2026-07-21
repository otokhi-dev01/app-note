import 'package:get/get.dart';

import '../../../notes/presentation/controllers/home_controller.dart';
import '../controllers/recycle_bin_controller.dart';

class RecycleBinBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RecycleBinController>(
      () => RecycleBinController(homeController: Get.find<HomeController>()),
    );
  }
}
