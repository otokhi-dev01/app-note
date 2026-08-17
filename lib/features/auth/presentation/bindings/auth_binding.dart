import 'package:get/get.dart';

import 'package:Note/features/auth/domain/usecases/auth_usecases.dart';
import 'package:Note/features/auth/presentation/controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // fenix so the controller survives being disposed and is shared between
    // the Login and Register routes.
    Get.lazyPut(
      () => AuthController(
        login: Get.find<Login>(),
        register: Get.find<Register>(),
        forgotPassword: Get.find<ForgotPassword>(),
      ),
      fenix: true,
    );
  }
}
