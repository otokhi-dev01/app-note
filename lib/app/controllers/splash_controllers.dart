import 'package:get/get.dart';
import '../../feature/auth/domain/repositories/auth_repository.dart';
import '../routes/app_routes.dart';

class SplashController extends GetxController {
  final AuthRepository authRepository;

  SplashController({
    required this.authRepository,
  });

  final RxString errorMessage = ''.obs;

  @override
  void onReady() {
    super.onReady();

    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    try {
      // Small delay so the splash screen is visible.
      await Future<void>.delayed(
        const Duration(milliseconds: 800),
      );

      final bool isLoggedIn =
      await authRepository.isLoggedIn();

      if (isLoggedIn) {
        Get.offAllNamed(AppRoutes.home);
      } else {
        Get.offAllNamed(AppRoutes.login);
      }
    } catch (error) {
      errorMessage.value = error.toString();

      // Even when secure storage has an error,
      // continue to the login screen.
      await Future<void>.delayed(
        const Duration(milliseconds: 500),
      );

      Get.offAllNamed(AppRoutes.login);
    }
  }
}