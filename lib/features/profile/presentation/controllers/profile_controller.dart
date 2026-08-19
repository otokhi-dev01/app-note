import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'package:Note/core/error/result.dart';
import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/core/storage/theme_storage.dart';
import 'package:Note/core/usecase/usecase.dart';
import 'package:Note/features/auth/domain/usecases/auth_usecases.dart';
import 'package:Note/features/profile/domain/repositories/profile_repository.dart';
import 'package:Note/features/profile/domain/usecases/profile_usecases.dart';
import 'package:Note/routes/app_pages.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';

class ProfileController extends GetxController {
  final UpdateUserName _updateUserName;
  final UpdateProfileImage _updateProfileImage;
  final Logout _logout;
  final ProfileRepository _profile;
  final ThemeStorage _theme;

  ProfileController({
    required UpdateUserName updateUserName,
    required UpdateProfileImage updateProfileImage,
    required Logout logout,
    required ProfileRepository profile,
    required ThemeStorage theme,
  }) : _updateUserName = updateUserName,
       _updateProfileImage = updateProfileImage,
       _logout = logout,
       _profile = profile,
       _theme = theme;

  final _picker = ImagePicker();
  final _guestMode = Get.find<GuestModeService>();

  RxBool get isGuestMode => _guestMode.isGuestMode;

  final userName = ''.obs;
  final userPhone = ''.obs;
  final userImagePath = ''.obs;
  final currentThemeMode = ThemeMode.system.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
    currentThemeMode.value = _theme.theme;
  }

  void _loadUserData() {
    final user = _profile.currentUser;
    userName.value = user?.fullName ?? (isGuestMode.value ? 'Guest' : 'User Name');
    userPhone.value = isGuestMode.value ? 'Not signed in' : (user?.phone ?? '');

    // The avatar is a local file path; drop it if the file is gone (app
    // reinstall, cache clear) so the UI falls back to the placeholder.
    final savedPath = user?.profileImage ?? '';
    userImagePath.value = savedPath.isNotEmpty && File(savedPath).existsSync()
        ? savedPath
        : '';
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
    switch (await _updateUserName(controller.text)) {
      case Ok(:final value):
        userName.value = value.fullName ?? userName.value;
        Get.back();
        AppSnackbar.success('Saved', 'Name updated');
      case Err(:final failure):
        AppSnackbar.failure('Could not update name', failure);
    }
  }

  Future<void> updateProfileImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (image == null) return;

    switch (await _updateProfileImage(image.path)) {
      case Ok():
        userImagePath.value = image.path;
        AppSnackbar.success('Saved', 'Profile image updated');
      case Err(:final failure):
        AppSnackbar.failure('Could not update profile image', failure);
    }
  }

  void changeTheme(ThemeMode mode) {
    currentThemeMode.value = mode;
    _theme.switchTheme(mode);
  }

  Future<void> logout() async {
    await _logout(const NoParams());
    // Show onboarding again on the next launch.
    GetStorage().write('isFirstTime', true);
    Get.offAllNamed(Routes.ONBOARDING);
  }

  /// Guest mode's way back to Welcome/Login — required so a device that
  /// started with "Continue without account" can still create a real account
  /// without reinstalling the app.
  void goToLogin() => Get.offAllNamed(Routes.LOGIN);
}

void _noOp() {}
