import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:Note/features/profile/presentation/controllers/credit_card_controller.dart';
import 'package:Note/features/profile/presentation/views/card_scan_view.dart';
import 'package:Note/features/profile/presentation/views/my_cards_view.dart';
import 'package:Note/routes/app_pages.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(() => Get.reset());

  testWidgets('Empty My Cards shows the new card after a full add round trip', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Get.put(CreditCardController());
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: Routes.MY_CARDS,
        getPages: AppPages.routes,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No cards added yet'), findsOneWidget);

    await tester.tap(find.text('Add New Card'));
    await tester.pumpAndSettle();
    expect(find.byType(CardScanView), findsOneWidget);

    await tester.ensureVisible(find.text('Enter Card Manually'));
    await tester.tap(find.text('Enter Card Manually'));
    await tester.pumpAndSettle();

    final controller = Get.find<CreditCardController>();
    controller.cardNumberController.text = '4242424242424242';
    controller.cardholderNameController.text = 'JANE DOE';
    controller.expiryMonth.value = '08';
    controller.expiryYear.value = '2030';
    controller.cardBrand.value = 'Visa';
    await tester.pump();

    await tester.ensureVisible(find.text('Save Card'));
    await tester.tap(find.text('Save Card'));
    await tester.pumpAndSettle();
    expect(find.text('Card Added Successfully!'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.byType(MyCardsView), findsOneWidget);
    expect(find.text('No cards added yet'), findsNothing);
    expect(find.text('JANE DOE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
