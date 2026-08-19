import 'dart:async';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/core/usecase/usecase.dart';
import 'package:Note/features/auth/domain/usecases/auth_usecases.dart';
import 'package:Note/routes/app_pages.dart';

class AccountController extends GetxController {
  final Logout _logout;
  final GuestModeService _guestMode;

  AccountController({
    required Logout logout,
    required GuestModeService guestMode,
  }) : _logout = logout,
       _guestMode = guestMode;

  RxBool get isGuestMode => _guestMode.isGuestMode;

  Future<void> logout() async {
    await _logout(const NoParams());
    // Show onboarding again on the next launch.
    unawaited(GetStorage().write('isFirstTime', true));
    unawaited(Get.offAllNamed(Routes.ONBOARDING));
  }

  /// Guest mode's way back to Welcome/Login — required so a device that
  /// started with "Continue without account" can still create a real account
  /// without reinstalling the app.
  void goToLogin() => Get.offAllNamed(Routes.LOGIN);
}
