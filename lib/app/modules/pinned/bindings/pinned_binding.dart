import 'package:get/get.dart';
import '../controllers/pinned_controller.dart';

class PinnedBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PinnedController>(
      () => PinnedController(),
    );
  }
}
