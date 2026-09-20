import 'package:get/get.dart';
import 'package:Note/features/profile/presentation/controllers/passport_scan_controller.dart';

class PassportScanBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PassportScanController>(() => PassportScanController());
  }
}
