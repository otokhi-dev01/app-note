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
import 'package:Note/core/storage/profile_extras_storage.dart';
import 'package:Note/core/theme/app_theme.dart';
import 'package:Note/core/theme/folder_appearance.dart';
import 'package:Note/features/profile/domain/repositories/profile_repository.dart';
import 'package:Note/features/profile/domain/usecases/profile_usecases.dart';
import 'package:Note/features/profile/presentation/widgets/edit_name_sheet.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';

class ProfileController extends GetxController {
  final UpdateUserName _updateUserName;
  final UpdateProfileImage _updateProfileImage;
  final ProfileRepository _profile;
  final ForgotPassword _forgotPassword;

  ProfileController({
    required UpdateUserName updateUserName,
    required UpdateProfileImage updateProfileImage,
    required ProfileRepository profile,
    required ForgotPassword forgotPassword,
  }) : _updateUserName = updateUserName,
       _updateProfileImage = updateProfileImage,
       _profile = profile,
       _forgotPassword = forgotPassword;

  final _picker = ImagePicker();
  final _guestMode = Get.find<GuestModeService>();
  final _extras = ProfileExtrasStorage();

  RxBool get isGuestMode => _guestMode.isGuestMode;

  final userName = ''.obs;
  final userPhone = ''.obs;
  final userImagePath = ''.obs;

  // Local-only fields — see [ProfileExtrasStorage] for why these don't
  // round-trip through the backend yet.
  final userUsername = ''.obs;
  final userAccount = ''.obs;
  final userEmail = ''.obs;
  final userJob = ''.obs;
  final userBio = ''.obs;
  final userColorHex = Rx<String?>(null);

  Color get userColor => FolderAppearance.parseHex(
    userColorHex.value ?? FolderAppearance.defaultColorValue,
  );

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

    userUsername.value = _extras.username;
    userAccount.value = _extras.account;
    userEmail.value = _extras.email;
    userJob.value = _extras.job;
    userBio.value = _extras.bio;
    userColorHex.value = _extras.colorHex;
  }

  Future<void> updateUserName() async {
    final context = Get.context;
    if (context == null) return;

    await EditNameSheet.show(
      context: context,
      initialName: userName.value,
      onSave: _saveUserName,
    );
  }

  Future<bool> _saveUserName(String name) async {
    switch (await _updateUserName(name)) {
      case Ok(:final value):
        userName.value = value.fullName ?? userName.value;
        AppSnackbar.success('saved_title'.tr, 'name_updated_message'.tr);
        return true;
      case Err(:final failure):
        AppSnackbar.failure('name_update_failed_title'.tr, failure);
        return false;
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

  Future<void> updateUsername() => _editTextField(
    title: 'edit_username_title'.tr,
    hint: 'edit_username_hint'.tr,
    initialValue: userUsername.value,
    onSave: (value) {
      _extras.username = value;
      userUsername.value = value;
    },
  );

  Future<void> updateAccount() => _editTextField(
    title: 'edit_account_title'.tr,
    hint: 'edit_account_hint'.tr,
    initialValue: userAccount.value,
    onSave: (value) {
      _extras.account = value;
      userAccount.value = value;
    },
  );

  Future<void> updateEmail() => _editTextField(
    title: 'edit_email_title'.tr,
    hint: 'edit_email_hint'.tr,
    initialValue: userEmail.value,
    keyboardType: TextInputType.emailAddress,
    onSave: (value) {
      _extras.email = value;
      userEmail.value = value;
    },
  );

  /// One sheet for both fields since "job" and "bio" are always described
  /// together in a single profile blurb rather than as separate settings.
  Future<void> updateJobAndBio() async {
    final context = Get.context;
    if (context == null) return;

    final jobController = TextEditingController(text: userJob.value);
    final bioController = TextEditingController(text: userBio.value);
    try {
      await CustomGlassSheet.show<void>(
        context: context,
        isScrollable: true,
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
                'edit_job_bio_title'.tr,
                style: Theme.of(sheetContext).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              CustomGlassTextField(
                controller: jobController,
                autofocus: true,
                placeholder: 'edit_job_hint'.tr,
                textInputAction: TextInputAction.next,
                textStyle: Theme.of(sheetContext).textTheme.bodyLarge,
                useOwnLayer: false,
              ),
              const SizedBox(height: 12),
              CustomGlassTextField(
                controller: bioController,
                placeholder: 'edit_bio_hint'.tr,
                maxLines: 4,
                minLines: 3,
                textInputAction: TextInputAction.newline,
                textStyle: Theme.of(sheetContext).textTheme.bodyLarge,
                useOwnLayer: false,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: CustomGlassButton(
                  onPressed: () {
                    _extras.job = jobController.text.trim();
                    _extras.bio = bioController.text.trim();
                    userJob.value = _extras.job;
                    userBio.value = _extras.bio;
                    Get.back();
                    AppSnackbar.success(
                      'saved_title'.tr,
                      'profile_updated_message'.tr,
                    );
                  },
                  semanticLabel: 'save_action'.tr,
                  borderRadius: 30,
                  foregroundColor: Colors.white,
                  glassColor: AppTheme.folderPink,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'save_action'.tr,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } finally {
      jobController.dispose();
      bioController.dispose();
    }
  }

  /// A swatch picker sheet reusing [FolderAppearance.colors] — the same
  /// palette folders pick from — rather than inventing a second one.
  Future<void> updateColor() async {
    final context = Get.context;
    if (context == null) return;

    await CustomGlassSheet.show<void>(
      context: context,
      isScrollable: false,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'edit_color_title'.tr,
              style: Theme.of(
                sheetContext,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Obx(
              () => Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (final hex in FolderAppearance.colors)
                    _ProfileColorSwatch(
                      hex: hex,
                      selected: userColorHex.value == hex,
                      onTap: () => selectColor(hex, closePicker: true),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Persists the accent used by the profile identity card.
  void selectColor(String hex, {bool closePicker = false}) {
    if (!FolderAppearance.colors.contains(hex)) return;

    _extras.colorHex = hex;
    userColorHex.value = hex;
    if (closePicker) Get.back();
    AppSnackbar.success('saved_title'.tr, 'profile_updated_message'.tr);
  }

  /// Reuses the same [ForgotPassword] use case the login screen's "Forgot
  /// password" link does — the backend has no reset route yet
  /// (`ApiCapabilities.forgotPassword`), so this surfaces that reason rather
  /// than pretending a link was sent.
  Future<void> requestPasswordReset() async {
    final context = Get.context;
    if (context == null || isGuestMode.value) return;

    final phone = userPhone.value;
    final confirmed = await CustomGlassSheet.show<bool>(
      context: context,
      isScrollable: false,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'reset_password_title'.tr,
              style: Theme.of(
                sheetContext,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'reset_password_desc'.tr,
              style: Theme.of(sheetContext).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: CustomGlassButton(
                onPressed: () => Navigator.of(sheetContext).pop(true),
                semanticLabel: 'reset_password_title'.tr,
                borderRadius: 30,
                foregroundColor: Colors.white,
                glassColor: AppTheme.folderPink,
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  'reset_password_title'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || phone.isEmpty) return;

    final result = await _forgotPassword(phone);
    if (result case Err(:final failure)) {
      AppSnackbar.failure('reset_password_title'.tr, failure);
    } else {
      AppSnackbar.success(
        'reset_request_sent_title'.tr,
        'reset_request_sent_message'.trParams({'phone': phone}),
      );
    }
  }

  /// Shared single-line text-field sheet for the local-only fields — same
  /// shape as [updateUserName]'s sheet, minus the network round trip.
  Future<void> _editTextField({
    required String title,
    required String hint,
    required String initialValue,
    required ValueChanged<String> onSave,
    TextInputType? keyboardType,
  }) async {
    final context = Get.context;
    if (context == null) return;

    final fieldController = TextEditingController(text: initialValue);
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
                title,
                style: Theme.of(sheetContext).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              CustomGlassTextField(
                controller: fieldController,
                autofocus: true,
                placeholder: hint,
                keyboardType: keyboardType,
                textInputAction: TextInputAction.done,
                textStyle: Theme.of(sheetContext).textTheme.bodyLarge,
                useOwnLayer: false,
                onSubmitted: (_) {
                  onSave(fieldController.text.trim());
                  Get.back();
                },
                suffixIcon: const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.folderPink,
                ),
                onSuffixTap: () {
                  onSave(fieldController.text.trim());
                  Get.back();
                },
              ),
            ],
          ),
        ),
      );
    } finally {
      fieldController.dispose();
    }
  }

  Future<void> logout() async {
    await Get.find<Logout>()(const NoParams());
    unawaited(Get.offAllNamed(Routes.ONBOARDING));
  }
}

/// A tappable color circle for [ProfileController.updateColor]'s sheet —
/// visually the same swatch as the folder color picker's, kept local to
/// Profile since it's a different sheet context.
class _ProfileColorSwatch extends StatelessWidget {
  final String hex;
  final bool selected;
  final VoidCallback onTap;

  const _ProfileColorSwatch({
    required this.hex,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = FolderAppearance.parseHex(hex);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: selected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: selected ? 0.5 : 0),
              blurRadius: 10,
            ),
          ],
        ),
        child: selected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
            : null,
      ),
    );
  }
}
