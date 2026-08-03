import 'package:get/get.dart';
import 'trash_controller.dart';

class TrashBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TrashController>(() => TrashController());
  }
}
