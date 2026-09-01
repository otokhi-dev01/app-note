import 'package:get/get.dart';
import 'package:Note/features/settings/presentation/controllers/appearance_controller.dart';

class AppearanceBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AppearanceController());
  }
}
