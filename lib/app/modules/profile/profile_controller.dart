import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/services/theme_service.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_pages.dart';

class ProfileController extends GetxController {
  final _storage = GetStorage();
  final _themeService = ThemeService();
  final _picker = ImagePicker();

  final userName = "User Name".obs;
  final userPhone = "0968734812".obs;
  final userImagePath = "".obs;
  final currentThemeMode = ThemeMode.system.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
    _loadCurrentTheme();
  }

  void _loadUserData() {
    userName.value = _storage.read('userName') ?? "User Name";
    userPhone.value = _storage.read('userPhone') ?? "0968734812";
    userImagePath.value = _storage.read('userImage') ?? "";
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
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                userName.value = nameController.text.trim();
                _storage.write('userName', userName.value);
                Get.back();
                Get.snackbar("Success", "Name updated");
              }
            },
            child: Text("Save", style: TextStyle(color: AppTheme.folderYellow)),
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
        _storage.write('userImage', image.path);
        Get.snackbar("Success", "Profile image updated");
      }
    } catch (e) {
      Get.snackbar("Error", "Could not update profile image");
    }
  }

  void _loadCurrentTheme() {
    final isDark = _storage.read('isDarkMode');
    if (isDark == null) {
      currentThemeMode.value = ThemeMode.system;
    } else {
      currentThemeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    }
  }

  void changeTheme(ThemeMode mode) {
    currentThemeMode.value = mode;
    _themeService.switchTheme(mode);
  }

  void logout() {
    _storage.remove('token');
    Get.offAllNamed(Routes.LOGIN);
  }
}
