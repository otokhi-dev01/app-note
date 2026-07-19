import 'package:get/get.dart';
import '../../domain/repositories/auth_repository.dart';
import '../controller/register_controller.dart';

class RegisterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RegisterController>(
          () => RegisterController(
        authRepository:
        Get.find<AuthRepository>(),
      ),
    );
  }
}