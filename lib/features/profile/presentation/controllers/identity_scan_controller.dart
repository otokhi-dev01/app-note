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
import 'package:Note/features/profile/domain/entities/national_id_card.dart';
import 'package:Note/features/profile/domain/entities/identity_document.dart';
import 'package:Note/features/profile/presentation/views/document_upload_view.dart';
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
/// 2. **Custom camera + backend OCR** (fallback): the app's own camera
///    screen captures the front/back photos, which are then sent to
///    [ScanNationalId] for server-side parsing (see that class's doc
///    comment — the backend contract is still unconfirmed).
///
/// Review & Upload submits the document to the account server, then applies
/// complete national-ID details to the local Profile screen.
class IdentityScanController extends GetxController {
  IdentityScanController(
    this._scanNationalId, {
    BlinkIdFlutter? scanner,
    String iosLicenseKey = const String.fromEnvironment(
      'BLINKID_IOS_LICENSE_KEY',
    ),
    String androidLicenseKey = const String.fromEnvironment(
      'BLINKID_ANDROID_LICENSE_KEY',
    ),
  }) : _scanner = scanner ?? BlinkIdFlutter(),
       _iosLicenseKey = iosLicenseKey.trim(),
       _androidLicenseKey = androidLicenseKey.trim();

  final ScanNationalId _scanNationalId;
  final BlinkIdFlutter _scanner;
  final String _iosLicenseKey;
  final String _androidLicenseKey;

  final currentStep = IdentityScanStep.main.obs;
  final card = Rxn<NationalIdCard>();
  final isLoading = false.obs;

  String? _pendingFrontPath;

  /// Starts a scan. Tries the licensed BlinkID SDK first; when no license is
  /// configured for this platform, falls back to the app's own camera
  /// screen (see [IdentityScanStep.scanning]).
  Future<void> onStartScan() async {
    if (isLoading.value || isClosed) return;
    _pendingFrontPath = null;

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
      debugPrint(
        '[BLINKID] No license configured for this platform — falling back '
        'to the manual camera + backend OCR flow. Configure '
        'BLINKID_IOS_LICENSE_KEY / BLINKID_ANDROID_LICENSE_KEY via '
        '--dart-define-from-file to use the BlinkID SDK instead.',
      );
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
      card.value = await _mapBlinkIdResult(result);
      currentStep.value = IdentityScanStep.main;
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

  /// Fallback path: called once the back photo is captured, which submits
  /// both photos to the backend for OCR (see [ScanNationalId]).
  void onBackCaptured(String path) {
    unawaited(_processScan(_pendingFrontPath, path));
  }

  Future<void> _processScan(String? frontPath, String backPath) async {
    if (frontPath == null) {
      // Nothing sensible to submit without a front photo — bail back to the
      // result screen rather than calling the backend with a gap.
      currentStep.value = IdentityScanStep.main;
      return;
    }
    currentStep.value = IdentityScanStep.processing;
    isLoading.value = true;
    final result = await _scanNationalId(
      ScanNationalIdParams(frontImagePath: frontPath, backImagePath: backPath),
    );
    if (isClosed) return;

    NationalIdCard? scanned;
    Object? backendFailure;
    switch (result) {
      case Ok(:final value):
        scanned = value;
      case Err(:final failure):
        backendFailure = failure;
    }

    // `AppConstants.identityApiUrl` is still an unconfirmed, proposed
    // backend contract (see that constant's doc comment) — it 404s today.
    // Rather than dead-end there, read the MRZ printed on the back of the
    // card on-device: no license and no server round trip needed. This
    // only ever fills what the MRZ carries (ID number, DOB, expiry, the
    // Latin name) — the Khmer-script fields still need manual entry, same
    // as before, since the on-device recognizer is Latin-script only (see
    // MrzReader's doc comment).
    if (scanned == null) {
      scanned = await _scanMrzLocally(frontPath, backPath);
      if (scanned != null) {
        debugPrint(
          '[IDENTITY SCAN] Backend unavailable ($backendFailure) — read '
          'the MRZ on-device instead.',
        );
      }
    }

    isLoading.value = false;
    if (scanned != null) {
      card.value = scanned;
    } else if (backendFailure != null) {
      // Keep whatever was previously verified rather than wiping it out on
      // a failed rescan attempt — the user can just try again.
      AppSnackbar.error(
        'identity_scan_failed_title'.tr,
        'identity_scan_failed_retry_message'.tr,
      );
    }
    currentStep.value = IdentityScanStep.main;
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
      final text = await NativeMediaServices.recognizeText(backPath);
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
      final uploaded = await Get.to<IdentityDocument>(
        () => DocumentUploadView(initialCard: scanned),
      );
      if (isClosed || uploaded == null) return;
      var savedLocally = true;
      // The upload API permits an omitted name/DOB. Do not fabricate values
      // merely to satisfy the local profile cache's required fields.
      if (uploaded.documentType.toLowerCase() == 'national id' &&
          uploaded.dateOfBirth != null && uploaded.fullName.isNotEmpty) {
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
