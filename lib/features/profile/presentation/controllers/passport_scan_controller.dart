import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/core/services/native_media_services.dart';
import 'package:Note/features/profile/domain/entities/mrz_reader.dart';
import 'package:Note/features/profile/domain/entities/passport_card.dart';
import 'package:Note/features/profile/presentation/controllers/profile_controller.dart';
import 'package:Note/features/profile/presentation/views/identity_camera_view.dart';

enum PassportScanStep { main, scanning, processing }

class PassportScanController extends GetxController {
  final Future<String> Function(String) _recognizeText;

  PassportScanController({
    Future<String> Function(String) recognizeText = NativeMediaServices.recognizeText,
  }) : _recognizeText = recognizeText;

  final currentStep = PassportScanStep.main.obs;
  final passport = Rxn<PassportCard>();
  final isLoading = false.obs;
  Worker? _passportWorker;

  @override
  void onInit() {
    super.onInit();
    final profile = Get.find<ProfileController>();
    passport.value = profile.passportCard.value;
    _passportWorker = ever(profile.passportCard, (val) => passport.value = val);
  }

  @override
  void onClose() {
    _passportWorker?.dispose();
    super.onClose();
  }

  void onStartScan() {
    currentStep.value = PassportScanStep.scanning;
  }

  void onRescan() {
    onStartScan();
  }

  void onCancelCamera() {
    currentStep.value = PassportScanStep.main;
  }

  void onPassportCaptured(String path) {
    _processPassport(path);
  }

  Future<void> _processPassport(String path) async {
    currentStep.value = PassportScanStep.processing;
    isLoading.value = true;
    try {
      final text = await _recognizeText(path);
      final scanned = MrzReader.parsePassport(text, imagePath: path);
      
      if (scanned == null) {
        AppSnackbar.error(
          'identity_scan_failed_title'.tr,
          'identity_scan_failed_retry_message'.tr,
        );
        currentStep.value = PassportScanStep.main;
      } else {
        passport.value = scanned;
        await Get.find<ProfileController>().savePassportInformation(scanned);
        currentStep.value = PassportScanStep.main;
      }
    } catch (e) {
      debugPrint('[PASSPORT SCAN ERROR] $e');
      AppSnackbar.error(
        'identity_scan_failed_title'.tr,
        'identity_scan_failed_generic_message'.tr,
      );
      currentStep.value = PassportScanStep.main;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> onDeletePassport() async {
    if (passport.value == null) return;
    isLoading.value = true;
    try {
      await Get.find<ProfileController>().deletePassportInformation(passport.value!.passportNumber);
      passport.value = null;
    } finally {
      isLoading.value = false;
    }
  }
}
