import 'dart:async';
import 'dart:io';

import 'package:Note/core/usecase/usecase.dart';
import 'package:Note/features/auth/domain/usecases/auth_usecases.dart';
import 'package:Note/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:Note/core/error/failures.dart';
import 'package:Note/core/error/result.dart';
import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/core/storage/app_media_storage.dart';
import 'package:Note/core/storage/id_information_storage.dart';
import 'package:Note/features/profile/domain/entities/national_id_card.dart';
import 'package:Note/features/profile/domain/entities/passport_card.dart';
import 'package:Note/core/storage/profile_extras_storage.dart';
import 'package:Note/core/storage/session_storage.dart';
import 'package:Note/core/theme/folder_appearance.dart';
import 'package:Note/core/theme/ios_semantic_colors.dart';
import 'package:Note/features/profile/domain/usecases/profile_usecases.dart';
import 'package:Note/features/profile/presentation/views/profile_edit_screen.dart';
import 'package:Note/features/profile/presentation/widgets/edit_job_bio_sheet.dart';
import 'package:Note/features/profile/presentation/widgets/edit_id_information_sheet.dart';
import 'package:Note/features/profile/presentation/widgets/edit_passport_information_sheet.dart';
import 'package:Note/features/profile/presentation/widgets/edit_name_sheet.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';

class ProfileController extends GetxController {
  final UpdateUserName _updateUserName;
  final UpdateProfileImage _updateProfileImage;
  final SessionStorage _session;
  Worker? _sessionWorker;
  Worker? _guestModeWorker;
  int _idInformationRevision = 0;

  ProfileController({
    required UpdateUserName updateUserName,
    required UpdateProfileImage updateProfileImage,
    required SessionStorage session,
    IdInformationStorage idStorage = const IdInformationStorage(),
  }) : _updateUserName = updateUserName,
       _updateProfileImage = updateProfileImage,
       _session = session,
       _idStorage = idStorage;

  final _picker = ImagePicker();
  final _guestMode = Get.find<GuestModeService>();
  final _extras = ProfileExtrasStorage();
  final IdInformationStorage _idStorage;

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
  final userHighSchool = ''.obs;
  final userFirstChildName = ''.obs;
  final userFatherName = ''.obs;
  final userMotherName = ''.obs;
  final userBio = ''.obs;
  final userColorHex = Rx<String?>(null);
  final identityCard = Rxn<NationalIdCard>();
  final identityCards = <NationalIdCard>[].obs;
  String? _loadedIdentityOwner;
  final userIdNumber = ''.obs;
  final userIdName = ''.obs;
  final userDateOfBirth = Rxn<DateTime>();
  final userPlaceOfBirth = ''.obs;
  final userCurrentAddress = ''.obs;
  final userIdExpiryDate = Rxn<DateTime>();

  final passportCard = Rxn<PassportCard>();
  final passportCards = <PassportCard>[].obs;
  final passportNumber = ''.obs;
  final passportName = ''.obs;
  final passportDob = Rxn<DateTime>();
  final passportGender = ''.obs;
  final passportNationality = ''.obs;
  final passportExpiryDate = Rxn<DateTime>();
  final passportIssuedDate = Rxn<DateTime>();
  final passportIssuingCountry = ''.obs;

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
    if (_loadedIdentityOwner != _idOwnerKey) {
      _loadedIdentityOwner = _idOwnerKey;
      identityCards.clear();
      identityCard.value = null;
      userIdNumber.value = '';
      userIdName.value = '';
      userDateOfBirth.value = null;
      userPlaceOfBirth.value = '';
      userCurrentAddress.value = '';
      userIdExpiryDate.value = null;

      passportCards.clear();
      passportCard.value = null;
      passportNumber.value = '';
      passportName.value = '';
      passportDob.value = null;
      passportGender.value = '';
      passportNationality.value = '';
      passportExpiryDate.value = null;
      passportIssuedDate.value = null;
      passportIssuingCountry.value = '';
    }
    final user = _session.user.value;
    final isGuest = isGuestMode.value && user == null;
    final apiName = user?.fullName?.trim() ?? '';
    final guestName = _extras.guestName.trim();

    userName.value = isGuest
        ? (guestName.isNotEmpty ? guestName : 'guest_label'.tr)
        : (apiName.isNotEmpty ? apiName : 'default_user_name'.tr);
    userPhone.value = isGuest
        ? 'not_signed_in'.tr
        : (user?.phone?.trim() ?? '');

    // The avatar is stored as a path relative to the documents directory
    // so it survives app container UUID changes on iOS. Resolve it to a real
    // absolute path for the File widget.
    final savedPath = isGuest
        ? _extras.guestImagePath
        : (user?.profileImage ?? '');
    final resolvedPath = await AppMediaStorage.resolve(savedPath);
    userImagePath.value =
        resolvedPath != null && File(resolvedPath).existsSync()
        ? resolvedPath
        : '';

    unawaited(_loadIdInformation());
    unawaited(_loadPassportInformation());
  }

  String get formattedDateOfBirth => _formatDate(userDateOfBirth.value);

  String get formattedIdExpiryDate => _formatDate(userIdExpiryDate.value);

  String get formattedPassportDob => _formatDate(passportDob.value);

  String get formattedPassportExpiryDate => _formatDate(passportExpiryDate.value);

  String get formattedPassportIssuedDate => _formatDate(passportIssuedDate.value);

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String get _idOwnerKey {
    // One on-device collection per guest — there's no account to scope by, but
    // ID information should still save and load like it does for a real one.
    if (isGuestMode.value) return 'guest';
    final user = _session.user.value;
    final id = user?.id?.trim() ?? '';
    if (id.isNotEmpty) return 'id:$id';
    final phone = user?.phone?.trim() ?? '';
    if (phone.isNotEmpty) return 'phone:$phone';
    // Neither a real session nor explicit guest mode — e.g. a session that
    // was just force-signed-out after a rejected token refresh (see
    // ApiClient._forceSignOut), which clears the user without turning guest
    // mode on. This screen is still reachable in that state, and scanning
    // an ID here should never silently fail to save just because of that —
    // fall back to the same on-device bucket a guest uses. A real account
    // gets its own key back the moment sign-in succeeds.
    return 'guest';
  }

  String get identityOwnerKey => _idOwnerKey;

  Future<void> _loadIdInformation() async {
    final revision = ++_idInformationRevision;
    final ownerKey = _idOwnerKey;
    if (ownerKey.isEmpty) {
      userIdNumber.value = '';
      userIdName.value = '';
      userDateOfBirth.value = null;
      userPlaceOfBirth.value = '';
      userCurrentAddress.value = '';
      userIdExpiryDate.value = null;
      return;
    }

    try {
      final stored = await _idStorage.read(ownerKey);
      final storedCard = await _idStorage.readCard(ownerKey);
      final storedCards = await _idStorage.readCards(ownerKey);
      if (ownerKey != _idOwnerKey || revision != _idInformationRevision) return;
      _showIdInformation(stored, storedCard, storedCards);
    } catch (error) {
      debugPrint('[ID INFORMATION LOAD ERROR] $error');
    }
  }

  /// Publish the selected card after every profile field has been updated.
  /// Both screens observe the same card, including its photos and both scripts.
  void _showIdInformation(
    StoredIdInformation stored,
    NationalIdCard? storedCard,
    List<NationalIdCard> storedCards,
  ) {
    userIdNumber.value = stored.idNumber;
    userIdName.value = stored.name;
    userDateOfBirth.value = stored.dateOfBirth;
    userPlaceOfBirth.value = stored.placeOfBirth;
    userCurrentAddress.value = stored.currentAddress;
    userIdExpiryDate.value = stored.expiryDate;
    identityCards.assignAll(storedCards);
    identityCard.value = storedCard;
  }

  Future<void> _loadPassportInformation() async {
    final ownerKey = _idOwnerKey;
    if (ownerKey.isEmpty) return;

    try {
      final stored = await _idStorage.readPassport(ownerKey);
      final storedPassports = await _idStorage.readPassports(ownerKey);
      if (ownerKey != _idOwnerKey) return;

      passportCard.value = stored;
      passportCards.assignAll(storedPassports);

      if (stored != null) {
        passportNumber.value = stored.passportNumber;
        passportName.value = stored.fullName;
        passportDob.value = stored.dateOfBirthAsDate;
        passportGender.value = stored.gender;
        passportNationality.value = stored.nationality;
        passportExpiryDate.value = stored.expiryDateAsDate;
        passportIssuedDate.value = stored.issuedDateAsDate;
        passportIssuingCountry.value = stored.issuingCountry;
      }
    } catch (error) {
      debugPrint('[PASSPORT INFORMATION LOAD ERROR] $error');
    }
  }

  Future<void> savePassportInformation(PassportCard passport) async {
    final ownerKey = _idOwnerKey;
    if (ownerKey.isEmpty) return;

    try {
      await _idStorage.savePassport(ownerKey: ownerKey, passport: passport);
      await _loadPassportInformation();
      AppSnackbar.success('saved_title'.tr, 'passport_information_saved'.tr);
    } catch (error) {
      debugPrint('[PASSPORT INFORMATION SAVE ERROR] $error');
      AppSnackbar.error(
        'id_information_save_failed_title'.tr,
        'id_information_save_failed_message'.tr,
      );
    }
  }

  Future<void> deletePassportInformation(String number) async {
    final ownerKey = _idOwnerKey;
    if (ownerKey.isEmpty) return;

    try {
      await _idStorage.deletePassport(ownerKey, number);
      await _loadPassportInformation();
      AppSnackbar.success('saved_title'.tr, 'passport_information_deleted'.tr);
    } catch (error) {
      debugPrint('[PASSPORT INFORMATION DELETE ERROR] $error');
      AppSnackbar.error('delete_failed_title'.tr, 'delete_failed_message'.tr);
    }
  }

  Future<void> clearIdInformation() async {
    final ownerKey = _idOwnerKey;
    if (ownerKey.isEmpty) return;
    try {
      final number = identityCard.value?.idNumber;
      if (number == null) return;
      ++_idInformationRevision;
      await _idStorage.deleteCard(ownerKey, number);
      if (ownerKey != _idOwnerKey) return;
      await _loadIdInformation();
      AppSnackbar.success('saved_title'.tr, 'id_information_deleted'.tr);
    } catch (error) {
      debugPrint('[ID INFORMATION DELETE ERROR] $error');
      AppSnackbar.error('delete_failed_title'.tr, 'delete_failed_message'.tr);
    }
  }

  Future<bool> selectIdentityCard(String idNumber) async {
    final ownerKey = _idOwnerKey;
    try {
      ++_idInformationRevision;
      await _idStorage.selectCard(ownerKey, idNumber);
      if (ownerKey != _idOwnerKey) return false;
      await _loadIdInformation();
      return ownerKey == _idOwnerKey &&
          identityCard.value?.idNumber == idNumber;
    } catch (_) {
      AppSnackbar.error(
        'id_information_save_failed_title'.tr,
        'id_information_save_failed_message'.tr,
      );
      return false;
    }
  }

  void _loadProfileExtras() {
    userUsername.value = _extras.username;
    userAccount.value = _extras.account;
    userEmail.value = _extras.email;
    userJob.value = _extras.job;
    userHighSchool.value = _extras.highSchool;
    userFirstChildName.value = _extras.firstChildName;
    userFatherName.value = _extras.fatherName;
    userMotherName.value = _extras.motherName;
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
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      AppSnackbar.failure(
        'name_update_failed_title'.tr,
        const ValidationFailure('Please enter your name.'),
      );
      return false;
    }
    // A guest has no session to patch (that's what "guest" means) — the name
    // is saved on-device instead, the same place a signed-in account's name
    // already lives today (see ProfileRepositoryImpl.updateName).
    if (isGuestMode.value) {
      _extras.guestName = trimmed;
      userName.value = trimmed;
      AppSnackbar.success('saved_title'.tr, 'name_updated_message'.tr);
      return true;
    }
    switch (await _updateUserName(trimmed)) {
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

      void applyPersisted() {
        userImagePath.value = persistedPath;
        if (previousPath != persistedPath) {
          unawaited(
            AppMediaStorage.deleteIfManaged(
              path: previousPath,
              folder: 'profile_images',
            ),
          );
        }
        AppSnackbar.success(
          'saved_title'.tr,
          'profile_image_updated_message'.tr,
        );
      }

      // A guest has no session to patch (see _saveUserName) — the avatar is
      // saved on-device instead, same as a signed-in account's already is.
      if (isGuestMode.value) {
        _extras.guestImagePath = relativePath;
        applyPersisted();
        return;
      }
      switch (await _updateProfileImage(relativePath)) {
        case Ok():
          applyPersisted();
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

  Future<void> updateHighSchool() => _editTextField(
    title: 'high_school_label'.tr,
    hint: 'high_school_hint'.tr,
    initialValue: userHighSchool.value,
    onSave: (value) {
      _extras.highSchool = value;
      userHighSchool.value = value;
    },
  );

  Future<void> updateFirstChildName() => _editTextField(
    title: 'first_child_name_label'.tr,
    hint: 'first_child_name_hint'.tr,
    initialValue: userFirstChildName.value,
    onSave: (value) {
      _extras.firstChildName = value;
      userFirstChildName.value = value;
    },
  );

  Future<void> updateFatherName() => _editTextField(
    title: 'father_name_label'.tr,
    hint: 'father_name_hint'.tr,
    initialValue: userFatherName.value,
    onSave: (value) {
      _extras.fatherName = value;
      userFatherName.value = value;
    },
  );

  Future<void> updateMotherName() => _editTextField(
    title: 'mother_name_label'.tr,
    hint: 'mother_name_hint'.tr,
    initialValue: userMotherName.value,
    onSave: (value) {
      _extras.motherName = value;
      userMotherName.value = value;
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
      initialPlaceOfBirth: userPlaceOfBirth.value,
      initialCurrentAddress: userCurrentAddress.value,
      initialExpiryDate: userIdExpiryDate.value,
      onSave:
          (
            idNumber,
            name,
            dateOfBirth,
            placeOfBirth,
            currentAddress,
            expiryDate,
          ) => _saveIdInformation(
            idNumber,
            name,
            dateOfBirth,
            placeOfBirth: placeOfBirth,
            currentAddress: currentAddress,
            expiryDate: expiryDate,
          ),
    );
  }

  Future<void> updatePassportInformation() async {
    final context = Get.context;
    if (context == null || _idOwnerKey.isEmpty) return;

    await EditPassportInformationSheet.show(
      context: context,
      initialCard: passportCard.value,
      onSave: savePassportInformation,
    );
  }

  Future<bool> _saveIdInformation(
    String idNumber,
    String name,
    DateTime? dateOfBirth, {
    String placeOfBirth = '',
    String currentAddress = '',
    DateTime? expiryDate,
    bool silent = false,
    NationalIdCard? scannedCard,
  }) async {
    final ownerKey = _idOwnerKey;
    if (ownerKey.isEmpty) return false;
    final revision = ++_idInformationRevision;

    try {
      await _idStorage.save(
        ownerKey: ownerKey,
        idNumber: idNumber,
        name: name,
        dateOfBirth: dateOfBirth,
        placeOfBirth: placeOfBirth,
        currentAddress: currentAddress,
        expiryDate: expiryDate,
        scannedCard: scannedCard,
      );
      final stored = await _idStorage.read(ownerKey);
      final storedCard = await _idStorage.readCard(ownerKey);
      final storedCards = await _idStorage.readCards(ownerKey);
      if (ownerKey != _idOwnerKey || revision != _idInformationRevision) {
        return false;
      }
      _showIdInformation(stored, storedCard, storedCards);
      if (!silent) {
        AppSnackbar.success('saved_title'.tr, 'id_information_saved'.tr);
      }
      return true;
    } catch (error) {
      debugPrint('[ID INFORMATION SAVE ERROR] $error');
      if (!silent) {
        AppSnackbar.error(
          'id_information_save_failed_title'.tr,
          'id_information_save_failed_message'.tr,
        );
      }
      return false;
    }
  }

  /// Saves recognized fields to the encrypted profile cache. Missing fields
  /// are preserved only for a rescan of the same document; never invent a DOB
  /// or mix another card's address into a new scan.
  Future<bool> applyScannedIdInformation({
    required String idNumber,
    required String name,
    DateTime? dateOfBirth,
    String placeOfBirth = '',
    String currentAddress = '',
    DateTime? expiryDate,
    String? expectedOwnerKey,
    NationalIdCard? scannedCard,
  }) {
    if (expectedOwnerKey != null && expectedOwnerKey != _idOwnerKey) {
      return Future.value(false);
    }
    final number = idNumber.trim();
    if (number.isEmpty) return Future.value(false);
    final sameDocument = number == userIdNumber.value;
    return _saveIdInformation(
      number,
      name.trim().isNotEmpty
          ? name.trim()
          : sameDocument
          ? userIdName.value
          : '',
      dateOfBirth ?? (sameDocument ? userDateOfBirth.value : null),
      placeOfBirth: placeOfBirth.isNotEmpty
          ? placeOfBirth
          : sameDocument
          ? userPlaceOfBirth.value
          : '',
      currentAddress: currentAddress.isNotEmpty
          ? currentAddress
          : sameDocument
          ? userCurrentAddress.value
          : '',
      expiryDate: expiryDate ?? (sameDocument ? userIdExpiryDate.value : null),
      silent: true,
      scannedCard: scannedCard,
    );
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
      arguments: {'initialAccount': userPhone.value},
    );
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
