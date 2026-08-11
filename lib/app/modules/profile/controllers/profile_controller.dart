import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get_storage/get_storage.dart';
import '../../../data/providers/session_service.dart';
import '../../../data/providers/theme_service.dart';
import '../../../routes/app_pages.dart';
import '../../../theme/app_theme.dart';

class ProfileController extends GetxController {
  final _sessionService = Get.find<SessionService>();
  final _themeService = ThemeService();
  final _picker = ImagePicker();

  final userName = "".obs;
  final userPhone = "".obs;
  final userImagePath = "".obs;
  final currentThemeMode = ThemeMode.system.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
    _loadCurrentTheme();
  }

  void _loadUserData() {
    final user = _sessionService.user.value;
    userName.value = user?.fullName ?? "User Name";
    userPhone.value = user?.phone ?? "";

    final savedPath = user?.profileImage ?? "";
    if (savedPath.isNotEmpty && File(savedPath).existsSync()) {
      userImagePath.value = savedPath;
    } else {
      userImagePath.value = "";
    }
  }

  void updateUserName() {
    final nameController = TextEditingController(text: userName.value);
    Get.dialog(
      AlertDialog(
        title: const Text("Edit Name"),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Enter your name"),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                userName.value = nameController.text.trim();
                // Update local session
                final currentUser = _sessionService.user.value;
                if (currentUser != null) {
                  await _sessionService.saveSession(
                    _sessionService.token.value ?? "",
                    currentUser.copyWith(fullName: userName.value),
                  );
                }
                Get.back();
                Get.snackbar("Success", "Name updated");
              }
            },
            child: const Text(
              "Save",
              style: TextStyle(color: AppTheme.folderPink),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> updateProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
      );

      if (image != null) {
        userImagePath.value = image.path;
        final currentUser = _sessionService.user.value;
        if (currentUser != null) {
          await _sessionService.saveSession(
            _sessionService.token.value ?? "",
            currentUser.copyWith(profileImage: image.path),
          );
        }
        Get.snackbar("Success", "Profile image updated");
      }
    } catch (e) {
      Get.snackbar("Error", "Could not update profile image");
    }
  }

  void _loadCurrentTheme() {
    // Current theme mode is retrieved from theme service
    currentThemeMode.value = _themeService.theme;
  }

  void changeTheme(ThemeMode mode) {
    currentThemeMode.value = mode;
    _themeService.switchTheme(mode);
  }

  void logout() async {
    await _sessionService.clearSession();
    // Reset onboarding flag so it shows up again as requested
    GetStorage().write('isFirstTime', true);
    Get.offAllNamed(Routes.ONBOARDING);
  }
}
