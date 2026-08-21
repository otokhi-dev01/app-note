import 'dart:async';
import 'dart:io';

import 'package:Note/core/usecase/usecase.dart';
import 'package:Note/features/auth/domain/usecases/auth_usecases.dart';
import 'package:Note/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:Note/core/error/result.dart';
import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/core/theme/app_theme.dart';
import 'package:Note/features/profile/domain/repositories/profile_repository.dart';
import 'package:Note/features/profile/domain/usecases/profile_usecases.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';

class ProfileController extends GetxController {
  final UpdateUserName _updateUserName;
  final UpdateProfileImage _updateProfileImage;
  final ProfileRepository _profile;

  ProfileController({
    required UpdateUserName updateUserName,
    required UpdateProfileImage updateProfileImage,
    required ProfileRepository profile,
  }) : _updateUserName = updateUserName,
       _updateProfileImage = updateProfileImage,
       _profile = profile;

  final _picker = ImagePicker();
  final _guestMode = Get.find<GuestModeService>();

  RxBool get isGuestMode => _guestMode.isGuestMode;

  final userName = ''.obs;
  final userPhone = ''.obs;
  final userImagePath = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }

  void _loadUserData() {
    final user = _profile.currentUser;
    userName.value =
        user?.fullName ??
        (isGuestMode.value ? 'guest_label'.tr : 'default_user_name'.tr);
    userPhone.value = isGuestMode.value
        ? 'not_signed_in'.tr
        : (user?.phone ?? '');

    // The avatar is a local file path; drop it if the file is gone (app
    // reinstall, cache clear) so the UI falls back to the placeholder.
    final savedPath = user?.profileImage ?? '';
    userImagePath.value = savedPath.isNotEmpty && File(savedPath).existsSync()
        ? savedPath
        : '';
  }

  /// Glass bottom-sheet popup (matching the language picker / forgot-password
  /// flows) rather than a center dialog, for a look consistent with the rest
  /// of the app's newer glass surfaces.
  Future<void> updateUserName() async {
    final context = Get.context;
    if (context == null) return;

    final nameController = TextEditingController(text: userName.value);
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
                'edit_name_title'.tr,
                style: Theme.of(sheetContext).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              CustomGlassTextField(
                controller: nameController,
                autofocus: true,
                placeholder: 'edit_name_hint'.tr,
                textInputAction: TextInputAction.done,
                textStyle: Theme.of(sheetContext).textTheme.bodyLarge,
                useOwnLayer: false,
                onSubmitted: (_) => _saveUserName(nameController),
                suffixIcon: const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.folderPink,
                ),
                onSuffixTap: () => _saveUserName(nameController),
              ),
            ],
          ),
        ),
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
        AppSnackbar.success('saved_title'.tr, 'name_updated_message'.tr);
      case Err(:final failure):
        AppSnackbar.failure('name_update_failed_title'.tr, failure);
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
        AppSnackbar.success(
          'saved_title'.tr,
          'profile_image_updated_message'.tr,
        );
      case Err(:final failure):
        AppSnackbar.failure('profile_image_update_failed_title'.tr, failure);
    }
  }

  Future<void> logout() async {
    await Get.find<Logout>()(const NoParams());
    unawaited(Get.offAllNamed(Routes.ONBOARDING));
  }
}
