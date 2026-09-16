import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/features/profile/domain/entities/credit_card.dart';
import 'package:Note/routes/app_pages.dart';
import 'package:blinkcard_flutter/blinkcard_flutter.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:Note/features/profile/data/services/ios_card_scanner.dart';
import 'package:Note/features/profile/domain/entities/card_text_parser.dart';

enum CardScanStep {
  intro,
  scanningFront,
  scanningBack,
  processing,
  result,
  confirmation,
  success,
  list,
}

class CreditCardController extends GetxController {
  CreditCardController({
    BlinkCardFlutter? scanner,
    IosCardScanner? iosScanner,
    String iosLicenseKey = const String.fromEnvironment(
      'BLINKCARD_IOS_LICENSE_KEY',
    ),
    String androidLicenseKey = const String.fromEnvironment(
      'BLINKCARD_ANDROID_LICENSE_KEY',
    ),
  }) : _scanner = scanner ?? BlinkCardFlutter(),
       _iosScanner = iosScanner ?? IosCardScanner(),
       _iosLicenseKey = iosLicenseKey.trim(),
       _androidLicenseKey = androidLicenseKey.trim();

  final BlinkCardFlutter _scanner;
  final IosCardScanner _iosScanner;
  final String _iosLicenseKey;
  final String _androidLicenseKey;

  final currentStep = CardScanStep.list.obs;
  final cards = <CreditCard>[].obs;
  final isLoading = false.obs;

  // Scanned data
  final scannedCard = Rxn<CreditCard>();

  // Controllers for editing
  final cardNumberController = TextEditingController();
  final cardholderNameController = TextEditingController();
  final expiryMonth = '01'.obs;
  final expiryYear = DateTime.now().year.toString().obs;
  final cvvController = TextEditingController();
  final cardBrand = 'Visa'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadCards();
  }

  void _loadCards() {
    // Mock cards for now
    cards.value = [
      const CreditCard(
        id: '1',
        cardNumber: '4532 3100 9999 1234',
        cardholderName: 'VUTHUL VUN',
        expiryMonth: '08',
        expiryYear: '2030',
        cvv: '123',
        cardBrand: 'Visa',
      ),
    ];
  }

  void startScanning() {
    currentStep.value = CardScanStep.intro;
    Get.toNamed(Routes.CARD_SCAN);
  }

  Future<void> onStartScanningPressed() => _performRealScan();

  Future<void> _performRealScan() async {
    if (isLoading.value || isClosed) return;

    final licenseKey = kIsWeb
        ? null
        : switch (defaultTargetPlatform) {
            TargetPlatform.android => _androidLicenseKey,
            TargetPlatform.iOS => _iosLicenseKey,
            _ => null,
          };
    if (licenseKey == null) {
      AppSnackbar.info(
        'Scan Unavailable',
        'Card scanning requires an iPhone or Android device.',
      );
      return;
    }
    if (licenseKey.isEmpty ||
        licenseKey.toUpperCase().startsWith('YOUR_') ||
        licenseKey.toUpperCase().contains('LICENSE_KEY') ||
        licenseKey.toLowerCase().endsWith('license-key')) {
      // No BlinkCard license configured for this platform. Fall back to the
      // app's own camera + on-device text recognition (Apple Vision on iOS,
      // ML Kit on Android — both are already implemented natively; see
      // NativeMediaServices), rather than blocking the feature entirely.
      await _performOnDeviceScan();
      return;
    }

    try {
      isLoading.value = true;
      final result = await _scanner.performScan(
        blinkCardSdkSettings: BlinkCardSdkSettings(licenseKey: licenseKey),
        blinkCardSessionSettings: BlinkCardSessionSettings(
          scanningSettings: ScanningSettings(
            croppedImageSettings: CroppedImageSettings(returnCardImage: true),
          ),
        ),
      );

      if (isClosed || result == null || result.cardAccounts.isEmpty) return;

      final account = result.cardAccounts.first;
      scannedCard.value = CreditCard(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        cardNumber: account.cardNumber,
        cardholderName: result.cardholderName ?? '',
        expiryMonth:
            account.expiryDate?.month?.toString().padLeft(2, '0') ?? '01',
        expiryYear: account.expiryDate?.year?.toString() ?? '2030',
        cvv: account.cvv ?? '',
        cardBrand: _mapIssuer(result.issuingNetwork),
      );
      _syncFormToScannedCard();
      await _startExtracting();
    } on PlatformException catch (e) {
      if (isClosed) return;
      final message = e.message?.toLowerCase() ?? '';
      if (message == 'scanning has been cancelled') return;
      if (message.contains('license') || message.contains('licence')) {
        debugPrint(
          '[BLINKCARD] License rejected. Check the platform, app ID, SDK version and expiry in the Microblink dashboard.',
        );
        AppSnackbar.error(
          'Scan Unavailable',
          'Card scanning could not be activated. Please contact support.',
        );
      } else {
        debugPrint('[BLINKCARD ERROR] ${e.code}');
        AppSnackbar.error(
          'Scan Failed',
          'An error occurred while scanning your card.',
        );
      }
    } catch (e) {
      if (isClosed) return;
      debugPrint('[BLINKCARD ERROR] ${e.runtimeType}');
      AppSnackbar.error(
        'Scan Failed',
        'An error occurred while scanning your card.',
      );
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  /// Scans using the app's own camera and on-device text recognition
  /// (Apple Vision on iOS, ML Kit on Android) instead of BlinkCard. Used
  /// whenever no BlinkCard license is configured for the current platform.
  Future<void> _performOnDeviceScan() async {
    try {
      isLoading.value = true;
      final card = await _iosScanner.scan();
      if (isClosed || card == null) return;
      scannedCard.value = card;
      _syncFormToScannedCard();
      await _startExtracting();
    } on CardTextNotFoundException {
      if (!isClosed)
        AppSnackbar.info(
          'Card Not Read',
          'Keep the whole card in focus and try again, or enter the details manually.',
        );
    } on CunningDocumentScannerException catch (e) {
      if (!isClosed)
        AppSnackbar.error(
          'Scan Unavailable',
          e.code == 'permission_denied'
              ? 'Allow camera access in Settings to scan your card.'
              : 'The camera could not open. Please try again.',
        );
    } catch (_) {
      if (!isClosed)
        AppSnackbar.error(
          'Scan Failed',
          'The card could not be read. Please try again.',
        );
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  void onEnterManually() {
    if (isLoading.value) return;
    scannedCard.value = null;
    cardNumberController.clear();
    cardholderNameController.clear();
    cvvController.clear();
    expiryMonth.value = '';
    expiryYear.value = '';
    cardBrand.value = 'Unknown';
    currentStep.value = CardScanStep.confirmation;
  }

  String _mapIssuer(String issuingNetwork) {
    switch (issuingNetwork.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '')) {
      case 'visa':
        return 'Visa';
      case 'mastercard':
        return 'Mastercard';
      case 'amex':
      case 'americanexpress':
        return 'AMEX';
      default:
        return issuingNetwork.trim().capitalizeFirst ?? 'Unknown';
    }
  }

  void onFrontScanned() {
    // This is handled by native BlinkCard UI, but kept for custom flow compatibility
    currentStep.value = CardScanStep.scanningBack;
  }

  void onBackScanned() {
    // This is handled by native BlinkCard UI
    _startExtracting();
  }

  /// Shows the "Extracting Card Information" screen briefly after a
  /// successful scan (BlinkCard's own camera UI, or the on-device OCR
  /// fallback) before moving on to the reviewable result.
  Future<void> _startExtracting() async {
    currentStep.value = CardScanStep.processing;
    await Future.delayed(const Duration(milliseconds: 900));
    if (!isClosed) currentStep.value = CardScanStep.result;
  }

  void _syncFormToScannedCard() {
    final card = scannedCard.value;
    if (card != null) {
      cardNumberController.text = card.cardNumber;
      cardholderNameController.text = card.cardholderName;
      expiryMonth.value = card.expiryMonth;
      expiryYear.value = card.expiryYear;
      cvvController.text = card.cvv;
      cardBrand.value = card.cardBrand;
    }
  }

  void onContinueToConfirmation() {
    currentStep.value = CardScanStep.confirmation;
  }

  void onSaveCardPressed() {
    final month = int.tryParse(expiryMonth.value);
    final year = int.tryParse(expiryYear.value);
    if (!CardTextParser.isValidNumber(cardNumberController.text) ||
        month == null ||
        month < 1 ||
        month > 12 ||
        year == null ||
        year < 2000) {
      AppSnackbar.info(
        'Check Card Details',
        'Enter a valid card number and expiry date.',
      );
      return;
    }
    final newCard = CreditCard(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cardNumber: cardNumberController.text,
      cardholderName: cardholderNameController.text,
      expiryMonth: expiryMonth.value,
      expiryYear: expiryYear.value,
      cvv: cvvController.text,
      cardBrand: cardBrand.value,
    );

    cards.add(newCard);
    currentStep.value = CardScanStep.success;
  }

  void onDonePressed() {
    Get.back();
    currentStep.value = CardScanStep.list;
  }

  Future<void> onRetakeScan() => _performRealScan();

  void onAddAnotherCard() {
    currentStep.value = CardScanStep.intro;
  }

  @override
  void onClose() {
    cardNumberController.dispose();
    cardholderNameController.dispose();
    cvvController.dispose();
    super.onClose();
  }
}
