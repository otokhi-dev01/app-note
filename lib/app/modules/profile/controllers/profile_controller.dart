import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get_storage/get_storage.dart';
import '../../../data/providers/session_service.dart';
import '../../../data/providers/theme_service.dart';
import '../../../routes/app_pages.dart';
import '../../../widgets/glass_widgets.dart';

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

  Future<void> updateUserName() async {
    final context = Get.context;
    if (context == null) return;

    final nameController = TextEditingController(text: userName.value);
    try {
      await CustomGlassDialog.show<void>(
        context: context,
        title: 'Edit Name',
        content: CustomGlassTextField(
          controller: nameController,
          autofocus: true,
          placeholder: 'Enter your name',
          textInputAction: TextInputAction.done,
          textStyle: Get.textTheme.bodyLarge,
          useOwnLayer: false,
          onSubmitted: (_) => _saveUserName(nameController),
        ),
        actions: [
          const CustomGlassDialogAction(label: 'Cancel', onPressed: _noOp),
          CustomGlassDialogAction(
            label: 'Save',
            isPrimary: true,
            closeOnPressed: false,
            onPressed: () => _saveUserName(nameController),
          ),
        ],
      );
    } finally {
      nameController.dispose();
    }
  }

  Future<void> _saveUserName(TextEditingController controller) async {
    final name = controller.text.trim();
    if (name.isEmpty) {
      Get.snackbar('Name required', 'Please enter your name.');
      return;
    }

    userName.value = name;
    final currentUser = _sessionService.user.value;
    if (currentUser != null) {
      await _sessionService.saveSession(
        _sessionService.token.value ?? '',
        currentUser.copyWith(fullName: name),
      );
    }
    Get.back();
    Get.snackbar(
      'Success',
      'Name updated',
      backgroundColor: Colors.green.withValues(alpha: 0.1),
      colorText: Colors.green,
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

void _noOp() {}
