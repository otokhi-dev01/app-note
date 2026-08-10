import 'package:get/get.dart';
import '../../../routes/app_pages.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _navigateToNext();
  }

  void _navigateToNext() async {
    // Elegant delay for the splash animation to finish
    await Future.delayed(const Duration(milliseconds: 3500));

    // Always navigate to onboarding after splash as requested
    Get.offAllNamed(Routes.ONBOARDING);
  }
}
