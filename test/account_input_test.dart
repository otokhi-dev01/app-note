import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';

import 'package:Note/core/localization/app_translations.dart';
import 'package:Note/features/auth/presentation/controllers/account_input_controller.dart';
import 'package:Note/features/auth/presentation/widgets/account_input_field.dart';

void main() {
  test('Account values preserve text and add a phone prefix only once', () {
    final controller = AccountInputController();
    addTearDown(controller.dispose);
    expect(controller.text, isEmpty);
    expect(controller.isPhoneInput, isFalse);

    controller.text = '12 345-678';
    expect(controller.isPhoneInput, isTrue);
    expect(controller.account, '+85512345678');
    expect(controller.text, '12 345-678');

    controller.text = '+44 (7700) 900123';
    expect(controller.country.code, 'GB');
    expect(controller.account, '+447700900123');

    controller.text = '+855 12345678';
    expect(controller.country.code, 'KH');
    expect(controller.account, '+85512345678');

    controller.text = '12345678';
    controller.selectCountry(countries.firstWhere((c) => c.code == 'KH'));
    expect(controller.account, '+85512345678');

    for (final account in ['123name', '123@example.com', ' name ']) {
      controller.text = account;
      expect(controller.isPhoneInput, isFalse);
      expect(controller.account, account.trim());
    }
    controller.clear();
    expect(controller.isPhoneInput, isFalse);
    expect(controller.account, isEmpty);
  });

  testWidgets('Typing switches the external picker without losing focus', (
    tester,
  ) async {
    final controller = AccountInputController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 280,
              child: AccountInputField(controller: controller),
            ),
          ),
        ),
      ),
    );
    final input = find.byType(EditableText);
    final picker = find.byKey(const ValueKey('account-country-picker'));
    expect(picker, findsNothing);

    await tester.enterText(input, '1');
    await tester.pump();
    final field = tester.widget<EditableText>(input);
    expect(field.focusNode.hasFocus, isTrue);
    expect(controller.selection.baseOffset, 1);
    expect(find.text('+855'), findsOneWidget);
    final fieldRect = tester.getRect(input);
    final pickerRect = tester.getRect(picker);
    expect(pickerRect.right, lessThan(fieldRect.left));

    await tester.enterText(input, '123@example.com');
    await tester.pump();
    expect(picker, findsNothing);
    expect(tester.widget<EditableText>(input).focusNode, same(field.focusNode));
    expect(field.focusNode.hasFocus, isTrue);

    await tester.enterText(input, '7700900123');
    await tester.pump();
    await tester.tap(picker);
    await tester.pumpAndSettle();
    expect(find.byType(CountryPickerDialog), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'United Kingdom');
    await tester.pump();
    await tester.tap(find.widgetWithText(ListTile, 'United Kingdom'));
    await tester.pumpAndSettle();
    expect(find.text('+44'), findsOneWidget);
    expect(controller.text, '7700900123');
    expect(controller.account, '+447700900123');

    controller.clear();
    await tester.pump();
    expect(picker, findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    Get.reset();
  });
}
