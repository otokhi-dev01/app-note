import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:Note/core/feedback/app_snackbar.dart';
import 'package:Note/features/profile/domain/entities/credit_card.dart';
import 'package:Note/routes/app_pages.dart';
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

  void startScanning() {
    currentStep.value = CardScanStep.intro;
    Get.toNamed(Routes.CARD_SCAN);
  }

  void onStartScanningPressed() {
    if (isLoading.value || isClosed) return;
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.iOS &&
            defaultTargetPlatform != TargetPlatform.android)) {
      AppSnackbar.info(
        'Scan Unavailable',
        'Card scanning requires an iPhone or Android device.',
      );
      return;
    }
    scannedCard.value = null;
    currentStep.value = CardScanStep.scanningFront;
  }

  void onCameraSideChanged(bool isFront) {
    currentStep.value = isFront
        ? CardScanStep.scanningFront
        : CardScanStep.scanningBack;
  }

  void onCancelCamera() {
    currentStep.value = CardScanStep.intro;
  }

  void onCameraScanComplete(CreditCard card) {
    if (isClosed) return;
    scannedCard.value = card;
    _syncFormToScannedCard();
    unawaited(_startExtracting());
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

  Future<void> _startExtracting() async {
    currentStep.value = CardScanStep.processing;
    await Future.delayed(const Duration(milliseconds: 900));
    if (!isClosed && currentStep.value == CardScanStep.processing) {
      currentStep.value = CardScanStep.result;
    }
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

  void onRetakeScan() => onStartScanningPressed();

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
