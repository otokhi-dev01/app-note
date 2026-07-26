import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../app/services/auth_service.dart';
import '../../app/services/storage_service.dart';

class SplashController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final StorageService _storage = Get.find<StorageService>();

  @override
  void onInit() {
    super.onInit();
    _navigateToNext();
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 2));
    
    if (_storage.isFirstTime) {
      Get.offAllNamed(AppRoutes.onboarding);
    } else if (_authService.isLoggedIn) {
      Get.offAllNamed(AppRoutes.home);
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
