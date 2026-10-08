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
    if (Get.isRegistered<AuthController>()) return;
    // Keep the form controller alive while signup replaces the login stack.
    // Otherwise GetX can close the instance held by the new login screen.
    Get.put(
      AuthController(
        login: Get.find<Login>(),
        register: Get.find<Register>(),
        googleLogin: Get.find<GoogleLogin>(),
      ),
      permanent: true,
    );
  }
}
