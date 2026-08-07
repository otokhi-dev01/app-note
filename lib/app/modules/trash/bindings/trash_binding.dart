import 'package:get/get.dart';
import '../controllers/trash_controller.dart';

class TrashBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TrashController>(() => TrashController());
  }
}
