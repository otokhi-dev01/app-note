import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/routes/app_pages.dart';

class OnboardingController extends GetxController {
  final pageController = PageController();
  final currentPage = 0.obs;
  final _guestMode = Get.find<GuestModeService>();

  final pages = [
    OnboardingData(
      title: "onboarding_page1_title".tr,
      description: "onboarding_page1_desc".tr,
      icon: Icons.lightbulb_outline,
    ),
    OnboardingData(
      title: "onboarding_page2_title".tr,
      description: "onboarding_page2_desc".tr,
      icon: Icons.folder_open,
    ),
    OnboardingData(
      title: "onboarding_page3_title".tr,
      description: "onboarding_page3_desc".tr,
      icon: Icons.sync,
    ),
  ];

  void onPageChanged(int index) {
    currentPage.value = index;
  }

  /// App Store guideline 5.1.1(v): note-taking must work without an account.
  /// Folders and notes created here live only on this device — see
  /// `FolderRepositoryRouter` / `NoteRepositoryRouter`.
  void continueWithoutAccount() {
    _guestMode.enable();
    Get.offAllNamed(Routes.FOLDER);
  }

  /// Pushed, not `offAllNamed` — Login/Register have a back button that
  /// should return here, since a visitor who backs out of either isn't
  /// signed in or guest yet and still needs a way to actually use the app.
  void goToLogin() => Get.toNamed(Routes.LOGIN);

  void goToRegister() => Get.toNamed(Routes.REGISTER);
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
  });
}
