import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../data/services/auth_service.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    final authService = Get.find<AuthService>();
    try {
      await authService.ready;
      if (authService.isLoggedIn) {
        Get.offAllNamed(AppRoutes.home);
        return;
      }
    } catch (_) {
      // Fall through to sign-in if session restoration fails.
    }

    if (Get.currentRoute != AppRoutes.login) {
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
