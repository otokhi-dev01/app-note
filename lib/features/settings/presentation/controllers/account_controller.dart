import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:Note/core/error/result.dart';
import 'package:Note/core/feedback/app_dialogs.dart';
import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/core/usecase/usecase.dart';
import 'package:Note/features/auth/domain/usecases/auth_usecases.dart';
import 'package:Note/routes/app_pages.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';

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

  /// "Delete Account" — a destructive-action warning first, then a password
  /// prompt as the reauthentication step Apple's guideline 5.1.1(v) allows,
  /// so the account can't be wiped by anyone who just picks up an unlocked
  /// phone. [DeleteAccount] hits the server to actually erase the account
  /// and its data; this only handles confirming intent and clearing up
  /// afterward.
  Future<void> startDeleteAccount() async {
    final confirmed = await AppDialogs.confirm(
      title: 'account_delete_confirm_title'.tr,
      confirmLabel: 'account_delete_button'.tr,
    );
    if (!confirmed) return;
    unawaited(_promptPasswordAndDelete());
  }

  Future<void> _promptPasswordAndDelete() async {
    final context = Get.context;
    if (context == null) return;

    final passwordController = TextEditingController();
    try {
      await CustomGlassSheet.show<void>(
        context: context,
        isScrollable: false,
        builder: (sheetContext) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            8,
            24,
            MediaQuery.viewInsetsOf(sheetContext).bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'account_confirm_password_title'.tr,
                style: Theme.of(sheetContext).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'account_confirm_password_subtitle'.tr,
                style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              CustomGlassTextField(
                controller: passwordController,
                autofocus: true,
                obscureText: true,
                placeholder: 'password_hint'.tr,
                textInputAction: TextInputAction.done,
                textStyle: Theme.of(sheetContext).textTheme.bodyLarge,
                useOwnLayer: false,
                onSubmitted: (_) => _confirmDelete(passwordController),
                suffixIcon: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.red,
                ),
                onSuffixTap: () => _confirmDelete(passwordController),
              ),
            ],
          ),
        ),
      );
    } finally {
      passwordController.dispose();
    }
  }

  Future<void> _confirmDelete(TextEditingController controller) async {
    switch (await _deleteAccount(controller.text)) {
      case Ok():
        // offAllNamed replaces the whole stack, taking this open sheet down
        // with it — same as logout, show onboarding again on next launch.
        unawaited(GetStorage().write('isFirstTime', true));
        unawaited(Get.offAllNamed(Routes.ONBOARDING));
        AppSnackbar.success(
          'account_deleted_title'.tr,
          'account_deleted_message'.tr,
        );
      case Err(:final failure):
        AppSnackbar.failure('account_delete_failed_title'.tr, failure);
    }
  }
}
