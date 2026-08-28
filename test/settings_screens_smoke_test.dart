import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'package:Note/core/di/injector.dart';
import 'package:Note/core/localization/app_translations.dart';
import 'package:Note/features/profile/presentation/views/profile_edit_screen.dart';
import 'package:Note/features/profile/presentation/widgets/edit_id_information_sheet.dart';
import 'package:Note/features/profile/presentation/widgets/edit_job_bio_sheet.dart';
import 'package:Note/features/profile/presentation/widgets/edit_name_sheet.dart';
import 'package:Note/features/settings/presentation/widgets/settings_app_bar.dart';
import 'package:Note/routes/app_pages.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/shared/widgets/language_popup.dart';
import 'package:Note/shared/widgets/language_toggle_button.dart';

void expectCreateNoteAppBar(WidgetTester tester) {
  final wrapper = find.byType(AppScreenSliverAppBar);
  expect(wrapper, findsOneWidget);

  final context = tester.element(wrapper);
  final appBar = tester.widget<CustomGlassSliverAppBar>(
    find.descendant(
      of: wrapper,
      matching: find.byType(CustomGlassSliverAppBar),
    ),
  );
  expect(appBar.toolbarHeight, 52);
  expect(appBar.expandedHeight, 52);
  expect(appBar.backgroundColor, Theme.of(context).scaffoldBackgroundColor);
  expect(appBar.shadow, kCreateNoteAppBarShadow);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => Directory.systemTemp.path,
        );
    await GetStorage.init('settings-screen-test');
    await LiquidGlassWidgets.initialize(enablePerformanceMonitor: false);
  });

  tearDown(() => Get.reset());

  for (final route in [
    Routes.PROFILE,
    Routes.NOTIFICATIONS,
    Routes.DEVICE,
    Routes.LANGUAGE,
    Routes.PERMISSIONS,
    Routes.PRIVACY_POLICY,
    Routes.CONTACT_US,
    Routes.HELP_CENTER,
    Routes.PRIVACY_SECURITY,
    Routes.FORGOT_PASSWORD,
    Routes.DELETE_ACCOUNT,
  ]) {
    testWidgets('$route builds without an exception', (tester) async {
      InitialBinding().dependencies();
      await tester.pumpWidget(
        LiquidGlassWidgets.wrap(
          brightnessResolver: Theme.maybeBrightnessOf,
          theme: GlassThemeData(
            light: const GlassThemeVariant(quality: GlassQuality.standard),
            dark: const GlassThemeVariant(quality: GlassQuality.standard),
          ),
          child: GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('en', 'US'),
            initialRoute: route,
            getPages: AppPages.routes,
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expectCreateNoteAppBar(tester);
      if (route == Routes.PROFILE) {
        final profileAppBar = tester.widget<AppScreenSliverAppBar>(
          find.byType(AppScreenSliverAppBar),
        );
        final backButton = profileAppBar.leading! as CustomGlassButton;
        expect(backButton.width, 44);
        expect(backButton.height, 44);
        expect(backButton.shape, GlassShape.circle);
        expect(backButton.blur, 10);
        expect(backButton.opacity, 0.15);
        expect(backButton.thickness, 8);
        expect(backButton.foregroundColor, isNull);
        expect(backButton.glassColor, isNull);
      }
      if (route != Routes.PROFILE && route != Routes.FORGOT_PASSWORD) {
        expect(find.byType(SettingsSliverAppBar), findsOneWidget);
      }
      if (route == Routes.PROFILE) {
        expect(find.text('Light Mode'), findsOneWidget);
        expect(find.text('Dark Mode'), findsOneWidget);
      }
      await tester.pump(const Duration(milliseconds: 1));
    });
  }

  for (final route in [Routes.LOGIN, Routes.REGISTER]) {
    testWidgets('$route builds without an app bar', (tester) async {
      InitialBinding().dependencies();
      await tester.pumpWidget(
        LiquidGlassWidgets.wrap(
          brightnessResolver: Theme.maybeBrightnessOf,
          theme: GlassThemeData(
            light: const GlassThemeVariant(quality: GlassQuality.standard),
            dark: const GlassThemeVariant(quality: GlassQuality.standard),
          ),
          child: GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('en', 'US'),
            initialRoute: route,
            getPages: AppPages.routes,
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(AppScreenSliverAppBar), findsNothing);
      expect(find.byType(CustomGlassSliverAppBar), findsNothing);
      expect(find.byType(LanguageToggleButton), findsOneWidget);
      expect(find.byType(LanguagePopup), findsOneWidget);
      final languageMenu = tester.widget<GlassMenu>(
        find.descendant(
          of: find.byType(LanguagePopup),
          matching: find.byType(GlassMenu),
        ),
      );
      expect(languageMenu.menuWidth, 250);
      expect(
        languageMenu.items.whereType<GlassMenuItem>().map((item) => item.title),
        ['English', 'ខ្មែរ'],
      );
      await tester.pump(const Duration(seconds: 2));
    });
  }

  final profileEditors = <Widget>[
    EditNameSheet(initialName: 'User', onSave: (_) async => true),
    EditJobBioSheet(
      initialJob: 'Designer',
      initialBio: 'Career summary',
      onSave: (_, _) async => true,
    ),
    EditIdInformationSheet(
      initialIdNumber: '123',
      initialName: 'User',
      initialDateOfBirth: DateTime(2000),
      onSave: (_, _, _) async => true,
    ),
  ];

  for (final editor in profileEditors) {
    testWidgets('${editor.runtimeType} builds as a full screen', (
      tester,
    ) async {
      await tester.pumpWidget(
        LiquidGlassWidgets.wrap(
          brightnessResolver: Theme.maybeBrightnessOf,
          theme: GlassThemeData(
            light: const GlassThemeVariant(quality: GlassQuality.standard),
            dark: const GlassThemeVariant(quality: GlassQuality.standard),
          ),
          child: GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('en', 'US'),
            home: ProfileEditScreen(title: 'Edit Profile', child: editor),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expectCreateNoteAppBar(tester);
    });
  }
}
