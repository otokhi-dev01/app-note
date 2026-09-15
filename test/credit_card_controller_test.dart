import 'dart:async';

import 'package:Note/features/profile/presentation/controllers/credit_card_controller.dart';
import 'package:Note/features/profile/data/services/ios_card_scanner.dart';
import 'package:Note/features/profile/domain/entities/credit_card.dart';
import 'package:Note/features/profile/presentation/views/card_scan_view.dart';
import 'package:blinkcard_flutter/blinkcard_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Scanner extends BlinkCardFlutter {
  int calls = 0;
  String? receivedLicense;
  Future<BlinkCardScanningResult?> Function()? scan;

  @override
  Future<BlinkCardScanningResult?> performScan({
    required BlinkCardSdkSettings blinkCardSdkSettings,
    required BlinkCardSessionSettings blinkCardSessionSettings,
    ScanningUxSettings? scanningUxSettings,
  }) async {
    calls++;
    receivedLicense = blinkCardSdkSettings.licenseKey;
    return scan == null ? null : await scan!();
  }
}

class _IosScanner extends IosCardScanner {
  int calls = 0;
  CreditCard? result;
  @override
  Future<CreditCard?> scan() async {
    calls++;
    return result;
  }
}

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));
    await tester.pump();
  }

  Future<void> finish(
    WidgetTester tester,
    CreditCardController controller,
  ) async {
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    controller.onDelete();
  }

  for (final key in [
    '',
    '   ',
    'YOUR_IOS_BLINKCARD_LICENSE_KEY',
    'ios-license-key',
  ]) {
    testWidgets('missing or placeholder license "$key" never opens the SDK', (
      tester,
    ) async {
      await mount(tester);
      final scanner = _Scanner();
      final controller = CreditCardController(
        scanner: scanner,
        androidLicenseKey: key,
      );

      await controller.onStartScanningPressed();
      await tester.pumpAndSettle();

      expect(scanner.calls, 0);
      expect(controller.isLoading.value, isFalse);
      expect(
        find.text('Card scanning has not been set up yet.'),
        findsOneWidget,
      );
      await finish(tester, controller);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  }

  testWidgets(
    'iPhone scans with Apple OCR when no BlinkCard key is configured',
    (tester) async {
      final blinkCard = _Scanner();
      final native = _IosScanner()
        ..result = const CreditCard(
          id: 'scan',
          cardNumber: '4242424242424242',
          cardholderName: '',
          expiryMonth: '',
          expiryYear: '',
          cvv: '',
          cardBrand: 'Visa',
        );
      final controller = CreditCardController(
        scanner: blinkCard,
        iosScanner: native,
      );
      await controller.onStartScanningPressed();
      expect(native.calls, 1);
      expect(blinkCard.calls, 0);
      expect(controller.currentStep.value, CardScanStep.result);
      expect(controller.cardNumberController.text, '4242424242424242');
      expect(controller.expiryMonth.value, isEmpty);
      expect(controller.isLoading.value, isFalse);
      controller.onDelete();
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets('cancelled Apple scan preserves the existing form', (
    tester,
  ) async {
    final controller = CreditCardController(iosScanner: _IosScanner());
    controller.currentStep.value = CardScanStep.intro;
    controller.cardNumberController.text = 'existing';
    await controller.onStartScanningPressed();
    expect(controller.currentStep.value, CardScanStep.intro);
    expect(controller.cardNumberController.text, 'existing');
    expect(controller.isLoading.value, isFalse);
    controller.onDelete();
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets(
    'native license rejection leaves the form intact and allows retry',
    (tester) async {
      await mount(tester);
      final scanner = _Scanner()
        ..scan = () async => throw PlatformException(
          code: 'blinkCardIos',
          message: 'Invalid license buffer size: 22',
        );
      final controller = CreditCardController(
        scanner: scanner,
        iosLicenseKey: 'test-configured-key',
      );
      controller.currentStep.value = CardScanStep.intro;
      controller.cardholderNameController.text = 'Existing name';

      await controller.onStartScanningPressed();
      await tester.pumpAndSettle();

      expect(controller.currentStep.value, CardScanStep.intro);
      expect(controller.cardholderNameController.text, 'Existing name');
      expect(controller.isLoading.value, isFalse);
      expect(
        find.text(
          'Card scanning could not be activated. Please contact support.',
        ),
        findsOneWidget,
      );
      scanner.scan = null;
      await controller.onRetakeScan();
      expect(scanner.calls, 2);
      await finish(tester, controller);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets('native scan cancellation does not display an error', (
    tester,
  ) async {
    await mount(tester);
    final scanner = _Scanner()
      ..scan = () async => throw PlatformException(
        code: 'blinkCardIos',
        message: 'Scanning has been cancelled',
      );
    final controller = CreditCardController(
      scanner: scanner,
      iosLicenseKey: 'test-configured-key',
    );
    controller.currentStep.value = CardScanStep.intro;

    await controller.onStartScanningPressed();
    await tester.pumpAndSettle();

    expect(controller.currentStep.value, CardScanStep.intro);
    expect(controller.isLoading.value, isFalse);
    expect(Get.isSnackbarOpen, isFalse);
    await finish(tester, controller);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets(
      '$platform uses its configured key and prevents overlapping scans',
      (tester) async {
        final pending = Completer<BlinkCardScanningResult?>();
        final scanner = _Scanner()..scan = () => pending.future;
        final controller = CreditCardController(
          scanner: scanner,
          iosLicenseKey: '  test-ios-key  ',
          androidLicenseKey: '  test-android-key  ',
        );

        final scanning = controller.onStartScanningPressed();
        await controller.onRetakeScan();
        expect(scanner.calls, 1);
        expect(
          scanner.receivedLicense,
          platform == TargetPlatform.iOS ? 'test-ios-key' : 'test-android-key',
        );
        expect(controller.isLoading.value, isTrue);
        pending.complete(null);
        await scanning;
        expect(controller.isLoading.value, isFalse);
        controller.onDelete();
      },
      variant: TargetPlatformVariant.only(platform),
    );
  }

  testWidgets('manual review supports empty dates and unknown brands', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = Get.put(CreditCardController());
    controller.onEnterManually();
    await tester.pumpWidget(const GetMaterialApp(home: CardScanView()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Select'), findsNWidgets(2));
    expect(find.text('Unknown'), findsOneWidget);
    controller.cardNumberController.text = '6011111111111117';
    controller.expiryMonth.value = '08';
    controller.expiryYear.value = '2045';
    await tester.pump();
    expect(tester.takeException(), isNull);
    controller.onSaveCardPressed();
    expect(controller.currentStep.value, CardScanStep.success);
    expect(controller.cards.last.cardBrand, 'Unknown');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
