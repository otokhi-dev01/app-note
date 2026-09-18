import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:Note/core/feedback/app_snackbar.dart';

void main() {
  tearDown(() => Get.reset());

  testWidgets('Notifications survive replacing a focused route and dismiss cleanly', (tester) async {
    Get.testMode = true;
    await tester.pumpWidget(GetMaterialApp(
      scaffoldMessengerKey: AppSnackbar.messengerKey,
      initialRoute: '/form',
      getPages: [
        GetPage(name: '/form', page: () => const Scaffold(body: TextField(autofocus: true))),
        GetPage(name: '/done', page: () => const Scaffold(body: Text('Destination'))),
      ],
    ));
    await tester.pumpAndSettle();
    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.focusNode.hasFocus, isTrue);
    AppSnackbar.error('Login failed', 'Try again.');
    await tester.pump(const Duration(milliseconds: 60));
    AppSnackbar.success('Signed in', 'Welcome.');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    unawaited(Get.offAllNamed<void>('/done'));
    await tester.pumpAndSettle();
    expect(find.text('Destination'), findsOneWidget);
    expect(find.text('Welcome.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('Welcome.'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
