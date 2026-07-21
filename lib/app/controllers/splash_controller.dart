import 'package:get/get.dart';

import '../../feature/auth/domain/repositories/auth_repository.dart';
import '../routes/app_routes.dart';

class SplashController extends GetxController {
  SplashController({required this.authRepository});

  final AuthRepository authRepository;
  final RxString errorMessage = ''.obs;

  @override
  void onReady() {
    super.onReady();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    try {
      await Future<void>.delayed(const Duration(milliseconds: 800));

      final bool isLoggedIn = await authRepository.isLoggedIn();
      Get.offAllNamed(isLoggedIn ? AppRoutes.home : AppRoutes.login);
    } catch (error) {
      errorMessage.value = error.toString();

      await Future<void>.delayed(const Duration(milliseconds: 500));
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
