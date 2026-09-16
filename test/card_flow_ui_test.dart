import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:Note/features/profile/domain/entities/credit_card.dart';
import 'package:Note/features/profile/presentation/controllers/credit_card_controller.dart';
import 'package:Note/features/profile/presentation/views/card_scan_view.dart';
import 'package:Note/features/profile/presentation/views/my_cards_view.dart';

const _card = CreditCard(
  id: 'test',
  cardNumber: '4532 3100 9999 1234',
  cardholderName: 'A VERY LONG CARDHOLDER NAME FOR LAYOUT CHECKING',
  expiryMonth: '08',
  expiryYear: '2030',
  cvv: '123',
  cardBrand: 'Visa',
);

void main() {
  setUp(() => Get.testMode = true);
  tearDown(() => Get.reset());

  for (final size in [const Size(320, 568), const Size(390, 844)]) {
    testWidgets('Card flow fits $size and supports scrolling', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = Get.put(CreditCardController());
      controller.scannedCard.value = _card;
      controller.cards.assignAll([_card]);
      controller.currentStep.value = CardScanStep.intro;
      await tester.pumpWidget(const GetMaterialApp(home: CardScanView()));
      for (final step in [
        CardScanStep.intro,
        CardScanStep.processing,
        CardScanStep.result,
        CardScanStep.confirmation,
        CardScanStep.success,
      ]) {
        controller.currentStep.value = step;
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: 'Layout at $step, $size',
        );
      }
      await tester.pumpWidget(const GetMaterialApp(home: MyCardsView()));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Add New Card'), findsOneWidget);
    });
  }

  testWidgets('Manual entry, CVV visibility, saving, and adding another card', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = Get.put(CreditCardController());
    controller.currentStep.value = CardScanStep.intro;
    await tester.pumpWidget(const GetMaterialApp(home: CardScanView()));
    await tester.ensureVisible(find.text('Enter Card Manually'));
    await tester.tap(find.text('Enter Card Manually'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm Details'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), '4242424242424242');
    await tester.enterText(find.byType(TextField).at(1), 'VUTHUL VUN');
    await tester.enterText(find.byType(TextField).at(2), '123');
    expect(
      tester.widget<TextField>(find.byType(TextField).at(2)).obscureText,
      isTrue,
    );
    await tester.tap(find.byTooltip('Show CVV'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).at(2)).obscureText,
      isFalse,
    );
    controller.expiryMonth.value = '08';
    controller.expiryYear.value = '2030';
    controller.cardBrand.value = 'Visa';
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save Card'));
    await tester.tap(find.text('Save Card'));
    await tester.pumpAndSettle();
    expect(find.text('Card Added Successfully!'), findsOneWidget);
    expect(controller.cards.last.cardholderName, 'VUTHUL VUN');
    await tester.ensureVisible(find.text('Add Another Card'));
    await tester.tap(find.text('Add Another Card'));
    await tester.pumpAndSettle();
    expect(find.text('Scan Your Card'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Empty list and dark confirmation render without errors', (
    tester,
  ) async {
    final controller = Get.put(CreditCardController());
    controller.cards.clear();
    await tester.pumpWidget(
      GetMaterialApp(theme: ThemeData.dark(), home: const MyCardsView()),
    );
    expect(find.text('No cards added yet'), findsOneWidget);
    controller.onEnterManually();
    await tester.pumpWidget(
      GetMaterialApp(theme: ThemeData.dark(), home: const CardScanView()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Confirm Details'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
