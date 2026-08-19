import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/routes/app_pages.dart';

class OnboardingController extends GetxController {
  final pageController = PageController();
  final currentPage = 0.obs;
  final _storage = GetStorage();
  final _sessionService = Get.find<SessionStorage>();
  final _guestMode = Get.find<GuestModeService>();

  final pages = [
    OnboardingData(
      title: "Capture Ideas",
      description: "Quickly write down your thoughts whenever they strike.",
      icon: Icons.lightbulb_outline,
    ),
    OnboardingData(
      title: "Organize Folders",
      description: "Keep your notes tidy with custom categories and colors.",
      icon: Icons.folder_open,
    ),
    OnboardingData(
      title: "Sync Anywhere",
      description: "Your notes are always with you, across all your devices.",
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
    _storage.write('isFirstTime', false);
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
    _storage.write('isFirstTime', false);
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
