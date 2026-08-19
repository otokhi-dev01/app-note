import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/routes/app_pages.dart';

class OnboardingController extends GetxController {
  final pageController = PageController();
  final currentPage = 0.obs;
  final _sessionService = Get.find<SessionStorage>();
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

  void nextPage() {
    if (currentPage.value < pages.length - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      skipOnboarding();
    }
  }

  void skipOnboarding() {
    if (!_sessionService.isLoggedIn) {
      Get.offAllNamed(Routes.LOGIN);
    } else {
      Get.offAllNamed(Routes.FOLDER);
    }
  }

  /// App Store guideline 5.1.1(v): note-taking must work without an account.
  /// Folders and notes created here live only on this device — see
  /// `FolderRepositoryRouter` / `NoteRepositoryRouter`.
  void continueWithoutAccount() {
    _guestMode.enable();
    Get.offAllNamed(Routes.FOLDER);
  }
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
