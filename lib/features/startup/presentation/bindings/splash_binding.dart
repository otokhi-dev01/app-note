import 'package:get/get.dart';
import 'package:notes/features/auth/domain/repositories/auth_repository.dart';
import 'package:notes/features/startup/presentation/controllers/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(SplashController(authRepository: Get.find<AuthRepository>()));
  }
}
