import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:blinkid_flutter/blinkid_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:Note/core/error/result.dart';
import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/core/services/native_media_services.dart';
import 'package:Note/features/profile/domain/entities/mrz_reader.dart';
import 'package:Note/features/profile/domain/entities/identity_scan_recognition.dart';
import 'package:Note/features/profile/domain/entities/identity_printed_text_reader.dart';
import 'package:Note/features/profile/data/services/identity_printed_text_service.dart';
import 'package:Note/features/profile/data/services/identity_image_service.dart';
import 'package:Note/features/profile/domain/entities/national_id_card.dart';
import 'package:Note/features/profile/domain/entities/identity_document.dart';
import 'package:Note/features/profile/presentation/views/document_upload_view.dart';
import 'package:Note/features/profile/presentation/views/identity_camera_view.dart';
import 'package:Note/features/profile/domain/usecases/identity_usecases.dart';
import 'package:Note/features/profile/presentation/controllers/profile_controller.dart';
import 'package:Note/routes/app_pages.dart';

enum IdentityScanStep { main, scanning, processing }

/// Drives the Digital Civic ID (national ID) scan-and-verify flow.
///
/// Scanning itself has two paths:
///
/// 1. **BlinkID** (preferred): [BlinkIdFlutter.performScan] launches
///    Microblink's native scanning UI, extracts the document data entirely
///    on-device, and hands back a [BlinkIdScanningResult] — no backend round
///    trip needed. Requires a license key (see `README`/`--dart-define`)
///    tied to this app's bundle/package id; falls through to (2) when one
///    isn't configured.
/// 2. **Custom camera + OCR**: live detection captures front/back photos;
///    local MRZ parsing runs first, with server OCR as a fallback.
///
/// Recognized details save automatically to the local, account-scoped Profile.
/// Review & Upload remains available to submit the document to the server.
class IdentityScanController extends GetxController {
  IdentityScanController(
    this._scanNationalId, {
    BlinkIdFlutter? scanner,
    Future<String?> Function()? scanCardImage,
    Future<String?> Function(IdentityCardExport) saveExport =
        IdentityImageService.save,
    Future<String> Function(String) recognizePrintedText =
        IdentityPrintedTextService.recognize,
    Future<String> Function(String) recognizeText =
        NativeMediaServices.recognizeText,
    String iosLicenseKey = const String.fromEnvironment(
      'BLINKID_IOS_LICENSE_KEY',
    ),
    String androidLicenseKey = const String.fromEnvironment(
      'BLINKID_ANDROID_LICENSE_KEY',
    ),
  }) : _scanner = scanner ?? BlinkIdFlutter(),
       _scanCardImage = scanCardImage,
       _saveExport = saveExport,
       _recognizeText = recognizeText,
       _recognizePrintedText = recognizePrintedText,
       _iosLicenseKey = iosLicenseKey.trim(),
       _androidLicenseKey = androidLicenseKey.trim();

  final ScanNationalId _scanNationalId;
  final Future<String?> Function()? _scanCardImage;
  final Future<String?> Function(IdentityCardExport) _saveExport;
  final Future<String> Function(String) _recognizeText;
  final Future<String> Function(String) _recognizePrintedText;
  final BlinkIdFlutter _scanner;
  final String _iosLicenseKey;
  final String _androidLicenseKey;

  final currentStep = IdentityScanStep.main.obs;
  final card = Rxn<NationalIdCard>();
  final isLoading = false.obs;
  final savedToProfile = false.obs;
  List<NationalIdCard> get savedCards =>
      Get.find<ProfileController>().identityCards;
  String? get defaultCardId =>
      Get.find<ProfileController>().identityCard.value?.idNumber;

  String? imagePath({required bool front}) =>
      front ? card.value?.frontImagePath : card.value?.backImagePath;

  String? _validatedFrontText;

  bool hasImage({required bool front}) {
    final path = imagePath(front: front);
    return path != null && File(path).existsSync();
  }

  Future<bool> _matchesCardSide(String path, {required bool front}) async {
    var text = '';
    try {
      text = await _recognizeText(path);
    } catch (_) {
      // Printed-text OCR also works when native recognition is unavailable.
    }
    if (isClosed) return false;
    if (IdentityScanRecognition.candidate(text, front: front) != null) {
      if (front) _validatedFrontText = text;
      return true;
    }
    try {
      text = await _recognizePrintedText(path);
    } catch (_) {
      return false;
    }
    final matches =
        !isClosed &&
        IdentityScanRecognition.candidate(text, front: front) != null;
    if (matches && front) _validatedFrontText = text;
    return matches;
  }

  Future<String?> _captureIdentitySide({required bool front}) async {
    return await Get.to<String>(
      () => IdentityCameraView(
        singleSideFront: front,
        validateCapture: (path) => _matchesCardSide(path, front: front),
        onFrontCaptured: (path) => Get.back(result: path),
        onBackCaptured: (path) => Get.back(result: path),
        onCancel: () => Get.back(),
      ),
    );
  }

  /// Captures one side. Rejects unreadable or wrong-side front images and
  /// reopens the scanner until a front is recognized or the user cancels.
  Future<void> onScanImage({required bool front}) async {
    if (isLoading.value || isClosed) return;
    final original = card.value;
    final profile = Get.find<ProfileController>();
    final owner = profile.identityOwnerKey;
    if (original == null && !front && !hasImage(front: true)) {
      AppSnackbar.info(
        'identity_scan_front'.tr,
        'identity_scan_front_first'.tr,
      );
      return;
    }
    bool isCurrent() =>
        !isClosed &&
        card.value == original &&
        owner == profile.identityOwnerKey;
    _validatedFrontText = null;
    isLoading.value = true;
    try {
      while (isCurrent()) {
        final scanImage = _scanCardImage;
        final path = scanImage == null
            ? await _captureIdentitySide(front: front)
            : await scanImage();
        if (path == null || !isCurrent()) return;
        if (!File(path).existsSync()) {
          throw const FileSystemException('Captured image is unavailable');
        }
        if (front && scanImage != null) {
          final matches = await _matchesCardSide(path, front: true);
          if (!isCurrent()) return;
          if (!matches) {
            AppSnackbar.info(
              'identity_scan_front'.tr,
              'identity_front_scan_retry'.tr,
            );
            continue;
          }
        }
        if (original == null) {
          final text = _validatedFrontText!;
          final number = IdentityScanRecognition.candidate(
            text,
            front: true,
          )!.split(':').first;
          // Persist the front immediately. Unread fields remain empty until
          // reviewed or scanned separately; no back image is required.
          card.value = IdentityPrintedTextReader.enrich(
            NationalIdCard(
              idNumber: number,
              nameKhmer: '',
              nameLatin: '',
              dateOfBirth: '',
              placeOfBirthKhmer: '',
              placeOfBirthEnglish: '',
              currentAddressKhmer: '',
              currentAddressEnglish: '',
              expiryDate: '',
              mrzLines: const [],
              chipIntegrityPercent: 0,
              frontImagePath: path,
            ),
            text,
          );
          _cardOwnerKey = owner;
        } else {
          var updatedCard = front
              ? original.copyWith(frontImagePath: path)
              : original.copyWith(backImagePath: path);
          try {
            final sideText = await _recognizePrintedText(path);
            updatedCard = IdentityPrintedTextReader.enrich(
              updatedCard,
              sideText,
            );
          } catch (_) {
            debugPrint('[IDENTITY SCAN] Printed text unavailable for side.');
          }
          card.value = updatedCard;
        }
        savedToProfile.value = false;
        await _saveCardToProfile();
        break;
      }
    } catch (_) {
      if (isCurrent()) {
        AppSnackbar.error(
          'identity_scan_failed_title'.tr,
          'identity_scan_failed_generic_message'.tr,
        );
      }
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  Future<void> onSaveCard() async {
    if (isLoading.value || isClosed || card.value == null) return;
    isLoading.value = true;
    try {
      await _saveCardToProfile();
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  /// A null side exports the card as a PNG; otherwise exports the original side.
  Future<void> onDownloadCard({bool? front}) async {
    final original = card.value;
    if (isLoading.value || isClosed || original == null) return;
    final owner = Get.find<ProfileController>().identityOwnerKey;
    isLoading.value = true;
    try {
      final export = front == null
          ? await IdentityImageService.card(original)
          : await IdentityImageService.image(original, front: front);
      if (isClosed ||
          card.value != original ||
          owner != Get.find<ProfileController>().identityOwnerKey) {
        return;
      }
      final destination = await _saveExport(export);
      if (!isClosed && destination != null) {
        AppSnackbar.success(
          'saved_title'.tr,
          (IdentityImageService.savesToPhotoLibrary
                  ? 'identity_saved_to_photos'
                  : 'identity_download_saved')
              .tr,
        );
      }
    } on PlatformException catch (error) {
      if (!isClosed) {
        AppSnackbar.error(
          'identity_save_failed_title'.tr,
          (error.code == 'PHOTO_PERMISSION_DENIED'
                  ? 'identity_photo_permission_denied'
                  : 'identity_download_failed')
              .tr,
        );
      }
    } catch (_) {
      if (!isClosed) {
        AppSnackbar.error(
          'identity_save_failed_title'.tr,
          'identity_download_failed'.tr,
        );
      }
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  Future<void> onAddIdentity() async {
    if (isLoading.value || isClosed) return;
    // Keep a failed save retryable before opening another scan.
    if (card.value != null && !savedToProfile.value) {
      isLoading.value = true;
      try {
        if (!await _saveCardToProfile()) return;
      } finally {
        if (!isClosed) isLoading.value = false;
      }
    }
    await onStartScan();
  }

  Future<void> onSelectIdentity(String? idNumber) async {
    if (idNumber == null || isLoading.value || isClosed) return;
    isLoading.value = true;
    try {
      if (card.value != null &&
          !savedToProfile.value &&
          !await _saveCardToProfile()) {
        return;
      }
      await Get.find<ProfileController>().selectIdentityCard(idNumber);
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  String? _scanOwnerKey;
  String? _cardOwnerKey;

  String? _pendingFrontPath;

  Worker? _profileCardWorker;

  @override
  void onInit() {
    super.onInit();
    final profile = Get.find<ProfileController>();
    void sync(NationalIdCard? saved) {
      _pendingFrontPath = null;
      card.value = saved;
      _cardOwnerKey = saved == null ? null : profile.identityOwnerKey;
      savedToProfile.value = saved != null;
    }

    sync(profile.identityCard.value);
    _profileCardWorker = ever(profile.identityCard, sync);
  }

  @override
  void onClose() {
    _profileCardWorker?.dispose();
    super.onClose();
  }

  Future<bool> saveCorrections(NationalIdCard edited) async {
    if (isClosed ||
        isLoading.value ||
        edited.idNumber != card.value?.idNumber ||
        _cardOwnerKey != Get.find<ProfileController>().identityOwnerKey) {
      return false;
    }
    isLoading.value = true;
    try {
      card.value = edited;
      savedToProfile.value = false;
      return await _saveCardToProfile();
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  /// Starts a scan. Tries the licensed BlinkID SDK first; when no license is
  /// configured for this platform, falls back to the app's own camera
  /// screen (see [IdentityScanStep.scanning]).
  Future<void> onStartScan() async {
    if (isLoading.value || isClosed) return;
    _pendingFrontPath = null;
    _scanOwnerKey = Get.find<ProfileController>().identityOwnerKey;

    final licenseKey = _resolveLicenseKey();
    if (licenseKey == null) {
      if (kIsWeb ||
          (defaultTargetPlatform != TargetPlatform.iOS &&
              defaultTargetPlatform != TargetPlatform.android)) {
        AppSnackbar.info(
          'identity_scan_unavailable_title'.tr,
          'identity_scan_unavailable_device_message'.tr,
        );
        return;
      }
      currentStep.value = IdentityScanStep.scanning;
      return;
    }
    await _performBlinkIdScan(licenseKey);
  }

  /// Re-scans, preferring BlinkID again even if a previous attempt fell
  /// back to the manual camera flow (e.g. after a license was fixed).
  void onRescan() {
    unawaited(onStartScan());
  }

  Future<void> onDeleteInfo() async {
    if (isLoading.value || isClosed) return;
    isLoading.value = true;
    try {
      final profile = Get.find<ProfileController>();
      if (savedToProfile.value) {
        await profile.clearIdInformation();
      } else {
        // Discard an unsaved draft without deleting the previously saved card.
        card.value = profile.identityCard.value;
        savedToProfile.value = card.value != null;
        _cardOwnerKey = card.value == null ? null : profile.identityOwnerKey;
      }
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  String? _resolveLicenseKey() {
    if (kIsWeb) return null;
    final key = switch (defaultTargetPlatform) {
      TargetPlatform.android => _androidLicenseKey,
      TargetPlatform.iOS => _iosLicenseKey,
      _ => null,
    };
    if (key == null || key.isEmpty) return null;
    final looksUnconfigured =
        key.toUpperCase().startsWith('YOUR_') ||
        key.toUpperCase().contains('LICENSE_KEY') ||
        key.toLowerCase().endsWith('license-key');
    return looksUnconfigured ? null : key;
  }

  Future<void> _performBlinkIdScan(String licenseKey) async {
    isLoading.value = true;
    try {
      final result = await _scanner.performScan(
        blinkIdSdkSettings: BlinkIdSdkSettings(licenseKey: licenseKey),
        blinkIdSessionSettings: BlinkIdSessionSettings(),
      );
      if (isClosed || result == null) return; // null == user cancelled.
      final scanned = await _mapBlinkIdResult(result);
      if (isClosed) return;
      await _completeScan(scanned);
      if (!isClosed) currentStep.value = IdentityScanStep.main;
    } on PlatformException catch (e) {
      if (isClosed) return;
      final message = e.message?.toLowerCase() ?? '';
      if (message.contains('cancel')) return;
      if (message.contains('licen')) {
        debugPrint(
          '[BLINKID] License rejected. Check the platform, app/bundle id, '
          'SDK version and expiry in the Microblink dashboard.',
        );
        AppSnackbar.error(
          'identity_scan_unavailable_title'.tr,
          'identity_scan_unavailable_license_message'.tr,
        );
      } else {
        debugPrint('[BLINKID ERROR] ${e.code}');
        AppSnackbar.error(
          'identity_scan_failed_title'.tr,
          'identity_scan_failed_generic_message'.tr,
        );
      }
    } catch (e) {
      if (isClosed) return;
      debugPrint('[BLINKID ERROR] ${e.runtimeType}');
      AppSnackbar.error(
        'identity_scan_failed_title'.tr,
        'identity_scan_failed_generic_message'.tr,
      );
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  /// Maps a fully on-device [BlinkIdScanningResult] to this app's
  /// [NationalIdCard]. BlinkID's `StringResult` exposes `value` (the raw
  /// OCR'd script — Khmer, for a Cambodian ID) and `latin` (transliterated,
  /// when the SDK can produce one); this uses `value` for the
  /// Khmer-script field and `latin` for the Latin-script one, since BlinkID
  /// has no dedicated "Khmer" alphabet field the way it does for
  /// arabic/cyrillic/greek.
  Future<NationalIdCard> _mapBlinkIdResult(BlinkIdScanningResult result) async {
    String local(StringResult? field) =>
        (field?.value ?? field?.latin ?? '').trim();
    String latin(StringResult? field) =>
        (field?.latin ?? field?.value ?? '').trim();
    String formatDate(DateResult<StringResult>? date) {
      final d = date?.date;
      if (d == null || d.day == null || d.month == null || d.year == null) {
        return '';
      }
      String two(int n) => n.toString().padLeft(2, '0');
      return '${two(d.day!)}-${two(d.month!)}-${d.year}';
    }

    final mrzLines = <String>[
      for (final side
          in result.subResults ?? const <SingleSideScanningResult>[])
        if ((side.mrz?.rawMRZString ?? '').isNotEmpty)
          ...side.mrz!.rawMRZString!.split('\n'),
    ];

    final localFirst = local(result.firstName);
    final localLast = local(result.lastName);
    final localFull = local(result.fullName);
    final nameLocal = localFull.isNotEmpty
        ? localFull
        : [localFirst, localLast].where((s) => s.isNotEmpty).join(' ');

    final latinName = [
      latin(result.firstName),
      latin(result.lastName),
    ].where((s) => s.isNotEmpty).join(' ');

    final idNumber = local(result.personalIdNumber).isNotEmpty
        ? local(result.personalIdNumber)
        : local(result.documentNumber);

    final frontImagePath = await _saveBase64Image(
      result.firstDocumentImage ?? result.firstInputImage,
      'id_front_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    final backImagePath = await _saveBase64Image(
      result.secondDocumentImage ?? result.secondInputImage,
      'id_back_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );

    return NationalIdCard(
      idNumber: idNumber,
      nameKhmer: nameLocal,
      nameLatin: latinName.isNotEmpty ? latinName : nameLocal,
      dateOfBirth: formatDate(result.dateOfBirth),
      placeOfBirthKhmer: local(result.placeOfBirth),
      placeOfBirthEnglish: latin(result.placeOfBirth),
      currentAddressKhmer: local(result.address),
      currentAddressEnglish: latin(result.address),
      expiryDate: formatDate(result.dateOfExpiry),
      mrzLines: mrzLines.isEmpty ? const [''] : mrzLines,
      frontImagePath: frontImagePath,
      backImagePath: backImagePath,
    );
  }

  /// BlinkID returns cropped document images as base64 strings rather than
  /// file paths; this writes one to a temp file so it can be shown the same
  /// way as the fallback camera flow's captured photos (`Image.file` via
  /// `IdentityPreviewCard`).
  Future<String?> _saveBase64Image(String? base64Image, String filename) async {
    if (base64Image == null || base64Image.isEmpty) return null;
    try {
      final bytes = base64Decode(base64Image);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  void onCancelCamera() {
    currentStep.value = IdentityScanStep.main;
  }

  /// Fallback path (no BlinkID license configured): called by the app's own
  /// camera screen once the front photo is captured.
  void onFrontCaptured(String path) {
    _pendingFrontPath = path;
  }

  /// Parses the captured back locally first, then tries server OCR if needed.
  Future<void> onBackCaptured(String path) =>
      _processScan(_pendingFrontPath, path);

  Future<void> _processScan(String? frontPath, String backPath) async {
    if (isClosed || isLoading.value) return;
    if (frontPath == null) {
      currentStep.value = IdentityScanStep.main;
      return;
    }
    currentStep.value = IdentityScanStep.processing;
    isLoading.value = true;
    try {
      var scanned = await _scanMrzLocally(frontPath, backPath);
      if (isClosed) return;
      if (scanned == null) {
        final result = await _scanNationalId(
          ScanNationalIdParams(
            frontImagePath: frontPath,
            backImagePath: backPath,
          ),
        );
        if (isClosed) return;
        if (result case Ok(:final value)) scanned = value;
      }
      if (scanned == null || scanned.idNumber.trim().isEmpty) {
        AppSnackbar.error(
          'identity_scan_failed_title'.tr,
          'identity_scan_failed_retry_message'.tr,
        );
      } else {
        await _completeScan(scanned);
      }
    } catch (_) {
      if (!isClosed) {
        AppSnackbar.error(
          'identity_scan_failed_title'.tr,
          'identity_scan_failed_retry_message'.tr,
        );
      }
    } finally {
      if (!isClosed) {
        isLoading.value = false;
        currentStep.value = IdentityScanStep.main;
      }
    }
  }

  Future<void> _completeScan(NationalIdCard scanned) async {
    final profile = Get.find<ProfileController>();
    for (final path in [scanned.frontImagePath, scanned.backImagePath]) {
      if (isClosed || _scanOwnerKey != profile.identityOwnerKey) return;
      if (path == null) continue;
      try {
        final text = await _recognizePrintedText(path);
        scanned = IdentityPrintedTextReader.enrich(scanned, text);
      } catch (_) {
        // Keep valid MRZ/BlinkID fields and offer correction for unreadable text.
        debugPrint(
          '[IDENTITY SCAN] Printed text unavailable for a captured side.',
        );
      }
    }
    if (isClosed || _scanOwnerKey != profile.identityOwnerKey) return;
    final previous = profile.identityCards
        .where((card) => card.idNumber == scanned.idNumber)
        .firstOrNull;
    card.value = scanned.fillMissingFrom(previous);
    _cardOwnerKey = _scanOwnerKey;
    savedToProfile.value = false;
    await _saveCardToProfile();
  }

  Future<bool> _saveCardToProfile() async {
    final scanned = card.value;
    if (scanned == null || isClosed || _cardOwnerKey == null) return false;
    final saved = await Get.find<ProfileController>().applyScannedIdInformation(
      idNumber: scanned.idNumber,
      name: scanned.nameLatin.isNotEmpty
          ? scanned.nameLatin
          : scanned.nameKhmer,
      dateOfBirth: scanned.dateOfBirthAsDate,
      placeOfBirth: [
        scanned.placeOfBirthKhmer,
        scanned.placeOfBirthEnglish,
      ].where((part) => part.isNotEmpty).join(' / '),
      currentAddress: [
        scanned.currentAddressKhmer,
        scanned.currentAddressEnglish,
      ].where((part) => part.isNotEmpty).join('\n'),
      expiryDate: scanned.expiryDateAsDate,
      expectedOwnerKey: _cardOwnerKey,
      scannedCard: scanned,
    );
    if (isClosed) return false;
    savedToProfile.value = saved;
    if (saved) card.value = Get.find<ProfileController>().identityCard.value;
    if (saved) {
      AppSnackbar.success('saved_title'.tr, 'id_information_saved'.tr);
    } else {
      AppSnackbar.error(
        'id_information_save_failed_title'.tr,
        'id_information_save_failed_message'.tr,
      );
    }
    return saved;
  }

  /// Opens the saved details, retrying a failed local save first.
  Future<void> onViewProfile() async {
    if (isClosed || isLoading.value || card.value == null) return;
    isLoading.value = true;
    try {
      if (_cardOwnerKey != Get.find<ProfileController>().identityOwnerKey) {
        AppSnackbar.error(
          'id_information_save_failed_title'.tr,
          'id_information_save_failed_message'.tr,
        );
        return;
      }
      final saved = savedToProfile.value || await _saveCardToProfile();
      if (saved && !isClosed) unawaited(Get.offNamed(Routes.PROFILE));
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  /// Reads the back photo's Machine Readable Zone on-device (see
  /// [MrzReader]) and, only when it parses, builds a [NationalIdCard] from
  /// it. Returns `null` on any failure — a missing/misread MRZ is treated
  /// the same as "couldn't scan," never as a partially-guessed result.
  Future<NationalIdCard?> _scanMrzLocally(
    String frontPath,
    String backPath,
  ) async {
    try {
      final text = await _recognizeText(backPath);
      return MrzReader.parse(
        text,
        frontImagePath: frontPath,
        backImagePath: backPath,
      );
    } catch (error) {
      debugPrint('[IDENTITY SCAN] On-device MRZ read failed: $error');
      return null;
    }
  }

  /// Reviews the fields/images and uploads them before updating local ID data.
  Future<void> onConfirm() async {
    if (isLoading.value || isClosed) return;
    isLoading.value = true;
    try {
      final scanned = card.value;
      final uploadOwnerKey = Get.find<ProfileController>().identityOwnerKey;
      final uploaded = await Get.to<IdentityDocument>(
        () => DocumentUploadView(initialCard: scanned),
      );
      if (isClosed || uploaded == null) return;
      var savedLocally = true;
      // The upload API permits an omitted name/DOB. Do not fabricate values
      // merely to satisfy the local profile cache's required fields.
      if (uploaded.documentType.toLowerCase() == 'national id' &&
          uploaded.dateOfBirth != null &&
          uploaded.fullName.isNotEmpty) {
        savedLocally = await Get.find<ProfileController>()
            .applyScannedIdInformation(
              idNumber: uploaded.documentNumber,
              name: uploaded.fullName,
              dateOfBirth: uploaded.dateOfBirth,
              placeOfBirth: [
                scanned?.placeOfBirthKhmer ?? '',
                scanned?.placeOfBirthEnglish ?? '',
              ].where((part) => part.isNotEmpty).join(' / '),
              currentAddress: [
                scanned?.currentAddressKhmer ?? '',
                scanned?.currentAddressEnglish ?? '',
              ].where((part) => part.isNotEmpty).join('\n'),
              expiryDate: uploaded.expiryDate,
              expectedOwnerKey: uploadOwnerKey,
            );
      }
      if (isClosed) return;
      AppSnackbar.success(
        'document_uploaded_title'.tr,
        (savedLocally
                ? 'document_uploaded_message'
                : 'document_uploaded_local_failed')
            .tr,
      );
      unawaited(Get.offNamed(Routes.PROFILE));
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }
}
