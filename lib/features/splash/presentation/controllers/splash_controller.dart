import 'dart:async';

import 'package:get/get.dart';
import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/routes/app_pages.dart';

class SplashController extends GetxController {
  final _session = Get.find<SessionStorage>();
  final _guestMode = Get.find<GuestModeService>();

  @override
  void onInit() {
    super.onInit();
    _navigateToNext();
  }

  void _navigateToNext() async {
    // Elegant delay for the splash animation to finish
    await Future.delayed(const Duration(milliseconds: 3500));

    // A returning signed-in user, or one who already chose "Continue
    // without account", has already seen onboarding — skip straight to
    // their notes instead of showing it again on every launch.
    if (_session.isLoggedIn || _guestMode.isGuestMode.value) {
      unawaited(Get.offAllNamed(Routes.FOLDER));
    } else {
      unawaited(Get.offAllNamed(Routes.ONBOARDING));
    }
  }
}
