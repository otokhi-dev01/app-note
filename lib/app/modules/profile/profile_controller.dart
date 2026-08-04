import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/services/session_service.dart';
import '../../data/services/theme_service.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_pages.dart';

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
    
    // Note: Profile image is currently handled separately in storage
    // If you want to store it in SessionService, you can update it there.
    userImagePath.value = ""; 
  }

  void updateUserName() {
    final nameController = TextEditingController(text: userName.value);
    Get.dialog(
      AlertDialog(
        title: const Text("Edit Name"),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Enter your name",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
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
            child: const Text("Save", style: TextStyle(color: AppTheme.folderYellow)),
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
        // You might want to save this path securely or upload it to a server
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
    Get.offAllNamed(Routes.LOGIN);
  }
}
