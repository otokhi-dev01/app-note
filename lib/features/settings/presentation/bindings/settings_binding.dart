import 'package:get/get.dart';
import 'package:notes/features/auth/domain/repositories/auth_repository.dart';
import 'package:notes/features/settings/domain/repositories/theme_repository.dart';
import 'package:notes/features/settings/presentation/controllers/settings_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SettingsController>(
      () => SettingsController(
        Get.find<ThemeRepository>(),
        Get.find<AuthRepository>(),
      ),
    );
  }
}
