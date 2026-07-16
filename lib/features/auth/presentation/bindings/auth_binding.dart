import 'package:get/get.dart';
import 'package:notes/features/auth/domain/repositories/auth_repository.dart';
import 'package:notes/features/auth/presentation/controllers/login_controller.dart';
import 'package:notes/features/auth/presentation/controllers/signup_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    final authRepository = Get.find<AuthRepository>();
    Get.lazyPut<LoginController>(
      () => LoginController(authRepository: authRepository),
    );
    Get.lazyPut<SignupController>(
      () => SignupController(authRepository: authRepository),
    );
  }
}
