import 'dart:async';
import 'dart:io';

import 'package:Note/core/usecase/usecase.dart';
import 'package:Note/features/auth/domain/usecases/auth_usecases.dart';
import 'package:Note/features/auth/presentation/widgets/forgot_password_popup.dart';
import 'package:Note/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:Note/core/error/result.dart';
import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/core/storage/profile_extras_storage.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/core/theme/app_theme.dart';
import 'package:Note/core/theme/folder_appearance.dart';
import 'package:Note/features/profile/domain/usecases/profile_usecases.dart';
import 'package:Note/features/profile/presentation/widgets/edit_job_bio_sheet.dart';
import 'package:Note/features/profile/presentation/widgets/edit_name_sheet.dart';
import 'package:Note/features/profile/presentation/widgets/profile_glass_popup.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';

class ProfileController extends GetxController {
  final UpdateUserName _updateUserName;
  final UpdateProfileImage _updateProfileImage;
  final SessionStorage _session;
  final ForgotPassword _forgotPassword;
  Worker? _sessionWorker;
  Worker? _guestModeWorker;

  ProfileController({
    required UpdateUserName updateUserName,
    required UpdateProfileImage updateProfileImage,
    required SessionStorage session,
    required ForgotPassword forgotPassword,
  }) : _updateUserName = updateUserName,
       _updateProfileImage = updateProfileImage,
       _session = session,
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
    _loadProfileExtras();
    _syncApiUser();
    _sessionWorker = ever(_session.user, (_) => _syncApiUser());
    _guestModeWorker = ever(_guestMode.isGuestMode, (_) => _syncApiUser());
  }

  void _syncApiUser() {
    final user = _session.user.value;
    final isGuest = isGuestMode.value && user == null;
    final apiName = user?.fullName?.trim() ?? '';

    userName.value = isGuest
        ? 'guest_label'.tr
        : (apiName.isNotEmpty ? apiName : 'default_user_name'.tr);
    userPhone.value = isGuest
        ? 'not_signed_in'.tr
        : (user?.phone?.trim() ?? '');

    // The avatar is a local file path; drop it if the file is gone (app
    // reinstall, cache clear) so the UI falls back to the placeholder.
    final savedPath = user?.profileImage ?? '';
    userImagePath.value = savedPath.isNotEmpty && File(savedPath).existsSync()
        ? savedPath
        : '';
  }

  void _loadProfileExtras() {
    userUsername.value = _extras.username;
    userAccount.value = _extras.account;
    userEmail.value = _extras.email;
    userJob.value = _extras.job;
    userBio.value = _extras.bio;
    userColorHex.value = _extras.colorHex;
  }

  @override
  void onClose() {
    _sessionWorker?.dispose();
    _guestModeWorker?.dispose();
    super.onClose();
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

    await EditJobBioSheet.show(
      context: context,
      initialJob: userJob.value,
      initialBio: userBio.value,
      onSave: (job, bio) async {
        _extras.job = job;
        _extras.bio = bio;
        userJob.value = job;
        userBio.value = bio;
        AppSnackbar.success('saved_title'.tr, 'profile_updated_message'.tr);
        return true;
      },
    );
  }

  /// A swatch picker sheet reusing [FolderAppearance.colors] — the same
  /// palette folders pick from — rather than inventing a second one.
  Future<void> updateColor() async {
    final context = Get.context;
    if (context == null) return;

    await ProfileGlassPopup.show<void>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(20),
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

  /// Opens the same validated forgot-password flow used by the Login screen.
  Future<void> requestForgotPassword() async {
    final context = Get.context;
    if (context == null || isGuestMode.value) return;

    await ForgotPasswordPopup.show(
      context: context,
      initialPhone: userPhone.value,
      onSubmit: _submitForgotPassword,
    );
  }

  Future<bool> _submitForgotPassword(String phone) async {
    final result = await _forgotPassword(phone);
    switch (result) {
      case Ok():
        AppSnackbar.success(
          'reset_request_sent_title'.tr,
          'reset_request_sent_message'.trParams({'phone': phone}),
        );
        return true;
      case Err(:final failure):
        AppSnackbar.failure('forgot_password_title'.tr, failure);
        return false;
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
      await ProfileGlassPopup.show<void>(
        context: context,
        builder: (sheetContext) => Padding(
          padding: const EdgeInsets.all(20),
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
