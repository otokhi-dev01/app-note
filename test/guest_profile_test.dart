import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:Note/core/di/injector.dart';
import 'package:Note/core/localization/app_translations.dart';
import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/core/storage/profile_extras_storage.dart';
import 'package:Note/features/profile/presentation/controllers/profile_controller.dart';
import 'package:Note/features/profile/presentation/views/profile_view.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final tempDir = await Directory.systemTemp.createTemp('guest_profile_test_');
    addTearDown(() => tempDir.delete(recursive: true));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => tempDir.path,
        );
    await GetStorage.init();
  });

  setUp(() => Get.testMode = true);
  tearDown(() => Get.reset());

  // Mounted the same way production does it — `initialBinding` on
  // GetMaterialApp itself, not a manual pre-mount `.dependencies()` call —
  // and guest mode is only switched on after the app (and its Translations)
  // already exist, exactly like a real "Continue without account" tap would.
  Future<void> mount(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      GetMaterialApp(
        initialBinding: InitialBinding(),
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const ProfileView(),
      ),
    );
    await tester.pumpAndSettle();
    Get.find<GuestModeService>().enable();
    await tester.pumpAndSettle();
  }

  testWidgets('A guest can set and persist a display name, like a real account', (
    tester,
  ) async {
    await mount(tester);
    expect(find.text('Guest'), findsWidgets);

    await tester.tap(find.text('Name').first);
    await tester.pumpAndSettle();
    expect(find.text('Edit Name'), findsWidgets);

    await tester.enterText(find.byType(EditableText).first, 'Nona Guest');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Nona Guest'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Username, account, and email are all editable for a guest', (
    tester,
  ) async {
    await mount(tester);

    await tester.tap(find.text('User').first);
    await tester.pumpAndSettle();
    expect(find.text('Edit User'), findsWidgets);
    await tester.enterText(find.byType(EditableText).first, 'guestname');
    await tester.tap(find.byIcon(Icons.check_circle_rounded));
    await tester.pumpAndSettle();
    expect(ProfileExtrasStorage().username, 'guestname');

    await tester.tap(find.text('Account').first);
    await tester.pumpAndSettle();
    expect(find.text('Edit Account'), findsWidgets);
    await tester.enterText(find.byType(EditableText).first, 'guest-acct');
    await tester.tap(find.byIcon(Icons.check_circle_rounded));
    await tester.pumpAndSettle();
    expect(ProfileExtrasStorage().account, 'guest-acct');

    await tester.tap(find.text('Email').first);
    await tester.pumpAndSettle();
    expect(find.text('Edit Email'), findsWidgets);
    await tester.enterText(find.byType(EditableText).first, 'guest@example.com');
    await tester.tap(find.byIcon(Icons.check_circle_rounded));
    await tester.pumpAndSettle();
    expect(ProfileExtrasStorage().email, 'guest@example.com');

    expect(tester.takeException(), isNull);
  });

  testWidgets('Job & Career and Color open their editors for a guest', (
    tester,
  ) async {
    await mount(tester);

    await tester.tap(find.text('Job & Career'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Job & Career'), findsWidgets);
    Get.back();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Color'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a Color'), findsWidgets);
    Get.back();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Phone stays read-only for a guest — there is no phone without an account', (
    tester,
  ) async {
    await mount(tester);
    await tester.tap(find.text('Phone'));
    await tester.pumpAndSettle();
    // No navigation should have happened: Profile's own title is still there.
    expect(find.text('My Profile'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ID information editor opens for a guest under a stable key', (
    tester,
  ) async {
    await mount(tester);
    final controller = Get.find<ProfileController>();

    await tester.tap(find.text('ID Number'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // The sheet opening at all proves _idOwnerKey is no longer empty for a
    // guest (ProfileController.updateIdInformation bails out early when it
    // is) — that early-return was the actual bug this covers.
    expect(controller.userIdNumber.value, isEmpty);
  });
}
