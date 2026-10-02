import 'package:get/get.dart';

import 'package:Note/features/auth/domain/usecases/auth_usecases.dart';
import 'package:Note/features/auth/presentation/controllers/auth_controller.dart';
import 'package:Note/features/auth/presentation/controllers/google_password_verification_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => GooglePasswordVerificationController(
        verify: Get.find<VerifyPasswordGoogle>(),
      ),
      fenix: true,
    );
    // Keep the existing login and password recovery controller available.
    // Email registration uses its own route-scoped RegistrationBinding.
    Get.lazyPut(
      () => AuthController(
        login: Get.find<Login>(),
        register: Get.find<Register>(),
        googleLogin: Get.find<GoogleLogin>(),
      ),
      fenix: true,
    );
  }
}
