import 'package:get/get.dart';
import 'package:notes/data/services/local_storage.dart';
import 'settings_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SettingsController>(
      () => SettingsController(Get.find<LocalStorage>()),
    );
  }
}
