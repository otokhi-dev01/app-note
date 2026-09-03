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
import 'package:Note/core/storage/app_media_storage.dart';
import 'package:Note/core/storage/id_information_storage.dart';
import 'package:Note/core/storage/profile_extras_storage.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/core/theme/folder_appearance.dart';
import 'package:Note/core/theme/ios_semantic_colors.dart';
import 'package:Note/features/profile/domain/usecases/profile_usecases.dart';
import 'package:Note/features/profile/presentation/views/profile_edit_screen.dart';
import 'package:Note/features/profile/presentation/widgets/edit_job_bio_sheet.dart';
import 'package:Note/features/profile/presentation/widgets/edit_id_information_sheet.dart';
import 'package:Note/features/profile/presentation/widgets/edit_name_sheet.dart';
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
  final _idStorage = const IdInformationStorage();

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
  final userIdNumber = ''.obs;
  final userIdName = ''.obs;
  final userDateOfBirth = Rxn<DateTime>();

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

  void _syncApiUser() async {
    final user = _session.user.value;
    final isGuest = isGuestMode.value && user == null;
    final apiName = user?.fullName?.trim() ?? '';

    userName.value = isGuest
        ? 'guest_label'.tr
        : (apiName.isNotEmpty ? apiName : 'default_user_name'.tr);
    userPhone.value = isGuest
        ? 'not_signed_in'.tr
        : (user?.phone?.trim() ?? '');

    // The avatar is stored as a path relative to the documents directory
    // so it survives app container UUID changes on iOS. Resolve it to a real
    // absolute path for the File widget.
    final savedPath = user?.profileImage ?? '';
    final resolvedPath = await AppMediaStorage.resolve(savedPath);
    userImagePath.value =
        resolvedPath != null && File(resolvedPath).existsSync()
            ? resolvedPath
            : '';

    unawaited(_loadIdInformation());
  }

  String get formattedDateOfBirth {
    final date = userDateOfBirth.value;
    if (date == null) return '';
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String get _idOwnerKey {
    if (isGuestMode.value) return '';
    final user = _session.user.value;
    final id = user?.id?.trim() ?? '';
    if (id.isNotEmpty) return 'id:$id';
    final phone = user?.phone?.trim() ?? '';
    return phone.isEmpty ? '' : 'phone:$phone';
  }

  Future<void> _loadIdInformation() async {
    final ownerKey = _idOwnerKey;
    if (ownerKey.isEmpty) {
      userIdNumber.value = '';
      userIdName.value = '';
      userDateOfBirth.value = null;
      return;
    }

    try {
      final stored = await _idStorage.read(ownerKey);
      if (ownerKey != _idOwnerKey) return;
      userIdNumber.value = stored.idNumber;
      userIdName.value = stored.name;
      userDateOfBirth.value = stored.dateOfBirth;
    } catch (error) {
      debugPrint('[ID INFORMATION LOAD ERROR] $error');
    }
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
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
      );
      if (image == null) return;

      final previousPath = userImagePath.value;
      final persistedPath = await AppMediaStorage.persist(
        sourcePath: image.path,
        folder: 'profile_images',
        fileName: 'profile_${DateTime.now().microsecondsSinceEpoch}',
      );
      final relativePath = await AppMediaStorage.makeRelative(persistedPath);

      switch (await _updateProfileImage(relativePath)) {
        case Ok():
          userImagePath.value = persistedPath;
          if (previousPath != persistedPath) {
            await AppMediaStorage.deleteIfManaged(
              path: previousPath,
              folder: 'profile_images',
            );
          }
          AppSnackbar.success(
            'saved_title'.tr,
            'profile_image_updated_message'.tr,
          );
        case Err(:final failure):
          await AppMediaStorage.deleteIfManaged(
            path: persistedPath,
            folder: 'profile_images',
          );
          AppSnackbar.failure('profile_image_update_failed_title'.tr, failure);
      }
    } catch (error) {
      debugPrint('[PROFILE IMAGE SAVE ERROR] $error');
      AppSnackbar.error(
        'profile_image_update_failed_title'.tr,
        'profile_image_save_failed_message'.tr,
      );
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

  /// The account phone is owned by authentication and cannot currently be
  /// changed by the profile API. It still gets a dedicated detail screen so
  /// the Profile row follows the same navigation model as every other field.
  Future<void> viewPhone() async {
    await Get.to<void>(
      () => ProfileEditScreen(
        title: 'phone_label'.tr,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'phone_number_label'.tr,
                style: Get.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                userPhone.value.isEmpty ? 'not_available'.tr : userPhone.value,
                style: Get.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'profile_phone_read_only'.tr,
                style: Get.textTheme.bodySmall?.copyWith(
                  color: Get.theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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

  Future<void> updateIdInformation() async {
    final context = Get.context;
    if (context == null || _idOwnerKey.isEmpty) return;

    await EditIdInformationSheet.show(
      context: context,
      initialIdNumber: userIdNumber.value,
      initialName: userIdName.value,
      initialDateOfBirth: userDateOfBirth.value,
      onSave: _saveIdInformation,
    );
  }

  Future<bool> _saveIdInformation(
    String idNumber,
    String name,
    DateTime dateOfBirth,
  ) async {
    final ownerKey = _idOwnerKey;
    if (ownerKey.isEmpty) return false;

    try {
      await _idStorage.save(
        ownerKey: ownerKey,
        idNumber: idNumber,
        name: name,
        dateOfBirth: dateOfBirth,
      );
      if (ownerKey != _idOwnerKey) return false;
      userIdNumber.value = idNumber;
      userIdName.value = name;
      userDateOfBirth.value = dateOfBirth;
      AppSnackbar.success('saved_title'.tr, 'id_information_saved'.tr);
      return true;
    } catch (error) {
      debugPrint('[ID INFORMATION SAVE ERROR] $error');
      AppSnackbar.error(
        'id_information_save_failed_title'.tr,
        'id_information_save_failed_message'.tr,
      );
      return false;
    }
  }

  /// A swatch picker sheet reusing [FolderAppearance.colors] — the same
  /// palette folders pick from — rather than inventing a second one.
  Future<void> updateColor() async {
    final context = Get.context;
    if (context == null) return;

    await Get.to<void>(
      () => ProfileEditScreen(
        title: 'edit_color_title'.tr,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'edit_color_title'.tr,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
    if (isGuestMode.value) return;

    await Get.toNamed(
      Routes.FORGOT_PASSWORD,
      arguments: {
        'initialPhone': userPhone.value,
        'onSubmit': submitForgotPassword,
      },
    );
  }

  Future<bool> submitForgotPassword(String phone) async {
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
      await Get.to<void>(
        () => ProfileEditScreen(
          title: title,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                  textStyle: Theme.of(context).textTheme.bodyLarge,
                  useOwnLayer: false,
                  onSubmitted: (_) {
                    onSave(fieldController.text.trim());
                    Get.back();
                  },
                  suffixIcon: const Icon(
                    Icons.check_circle_rounded,
                    color: IosSemanticColors.blue,
                  ),
                  onSuffixTap: () {
                    onSave(fieldController.text.trim());
                    Get.back();
                  },
                ),
              ],
            ),
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
