import 'package:get/get.dart';
import 'package:Note/core/network/api_client.dart';
import 'package:Note/features/auth/data/services/registration_service.dart';
import 'package:Note/features/auth/presentation/controllers/registration_controller.dart';

class RegistrationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => RegistrationController(RegistrationService(Get.find<ApiClient>())),
    );
  }
}
