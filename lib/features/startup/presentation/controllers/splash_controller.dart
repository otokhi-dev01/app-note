import 'package:get/get.dart';
import 'package:notes/app/navigation/app_routes.dart';
import 'package:notes/features/auth/domain/repositories/auth_repository.dart';

class SplashController extends GetxController {
  SplashController({AuthRepository? authRepository})
    : _authRepository = authRepository;

  final AuthRepository? _authRepository;

  @override
  void onInit() {
    super.onInit();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    final authRepository = _authRepository ?? Get.find<AuthRepository>();
    try {
      await authRepository.ready;
      if (authRepository.isLoggedIn) {
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
