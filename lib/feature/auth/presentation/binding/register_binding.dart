import 'package:get/get.dart';
import 'package:note_app/core/network/api_client.dart';
import 'package:note_app/core/storage/token_storage.dart';
import 'package:note_app/feature/auth/data/repositories/auth_repository_impl.dart';
import 'package:note_app/feature/auth/domain/repositories/auth_repository.dart';

import '../controller/register_controller.dart';

class RegisterBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AuthRepository>()) {
      Get.put<AuthRepository>(
        AuthRepositoryImpl(
          apiClient: Get.find<ApiClient>(),
          tokenStorage: Get.find<TokenStorage>(),
        ),
        permanent: true,
      );
    }

    if (!Get.isRegistered<RegisterController>()) {
      Get.lazyPut<RegisterController>(
            () => RegisterController(
              authRepository: Get.find<AuthRepository>(),
            ),
        fenix: false,
      );
    }
  }
}