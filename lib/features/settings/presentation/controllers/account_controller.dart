import 'dart:async';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:Note/core/error/result.dart';
import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/core/usecase/usecase.dart';
import 'package:Note/features/auth/domain/usecases/auth_usecases.dart';
import 'package:Note/routes/app_pages.dart';

class AccountController extends GetxController {
  final Logout _logout;
  final DeleteAccount _deleteAccount;
  final GuestModeService _guestMode;

  AccountController({
    required Logout logout,
    required DeleteAccount deleteAccount,
    required GuestModeService guestMode,
  }) : _logout = logout,
       _deleteAccount = deleteAccount,
       _guestMode = guestMode;

  RxBool get isGuestMode => _guestMode.isGuestMode;
  final isDeleting = false.obs;

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

  /// Permanently deletes the signed-in account after password
  /// reauthentication. The dedicated delete-account screen owns the warning
  /// and password UI; this method owns only the operation and its result.
  Future<bool> deleteAccount(String password) async {
    if (isDeleting.value) return false;
    if (password.isEmpty) {
      AppSnackbar.warning(
        'account_confirm_password_title'.tr,
        'validator_password_required'.tr,
      );
      return false;
    }

    isDeleting.value = true;
    try {
      switch (await _deleteAccount(password)) {
        case Ok():
          unawaited(GetStorage().write('isFirstTime', true));
          unawaited(Get.offAllNamed(Routes.ONBOARDING));
          AppSnackbar.success(
            'account_deleted_title'.tr,
            'account_deleted_message'.tr,
          );
          return true;
        case Err(:final failure):
          AppSnackbar.failure('account_delete_failed_title'.tr, failure);
          return false;
      }
    } finally {
      isDeleting.value = false;
    }
  }
}
