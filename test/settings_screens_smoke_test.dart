import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'package:Note/core/di/injector.dart';
import 'package:Note/core/localization/app_translations.dart';
import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/features/profile/presentation/views/profile_edit_screen.dart';
import 'package:Note/features/profile/presentation/widgets/edit_id_information_sheet.dart';
import 'package:Note/features/profile/presentation/widgets/edit_job_bio_sheet.dart';
import 'package:Note/features/profile/presentation/widgets/edit_name_sheet.dart';
import 'package:Note/features/settings/presentation/widgets/settings_app_bar.dart';
import 'package:Note/features/settings/presentation/widgets/settings_drawer.dart';
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

  for (final destination in [
    (label: 'Notifications', route: Routes.NOTIFICATIONS),
    (label: 'Privacy Policy', route: Routes.PRIVACY_POLICY),
    (label: 'Contact Us', route: Routes.CONTACT_US),
    (label: 'Permissions', route: Routes.PERMISSIONS),
    (label: 'Forgot Password', route: Routes.FORGOT_PASSWORD),
    (label: 'Help Center', route: Routes.HELP_CENTER),
    (label: 'Privacy & Security', route: Routes.PRIVACY_SECURITY),
    (label: 'Delete Account', route: Routes.DELETE_ACCOUNT),
  ]) {
    testWidgets('${destination.label} back arrow returns to Settings', (
      tester,
    ) async {
      InitialBinding().dependencies();
      Get.find<GuestModeService>().disable();

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
            getPages: AppPages.routes,
            home: Scaffold(
              key: settingsHostScaffoldKey,
              drawer: const SettingsDrawer(),
              body: const SizedBox.expand(),
            ),
          ),
        ),
      );

      await tester.pump();
      settingsHostScaffoldKey.currentState!.openDrawer();
      await tester.pumpAndSettle();
      final tile = find.text(destination.label);
      await tester.scrollUntilVisible(
        tile,
        280,
        scrollable: find
            .descendant(
              of: find.byType(SettingsDrawer),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(tile);
      if (destination.route == Routes.PERMISSIONS) {
        await tester.pump(kThemeAnimationDuration);
        await tester.pump(const Duration(milliseconds: 400));
      } else {
        await tester.pumpAndSettle();
      }
      expect(Get.currentRoute, destination.route);

      await tester.tap(find.byIcon(CupertinoIcons.back));
      await tester.pumpAndSettle();

      expect(Get.currentRoute, isNot(destination.route));
      expect(settingsHostScaffoldKey.currentState!.isDrawerOpen, isTrue);
      expect(find.byType(SettingsDrawer), findsOneWidget);
    });
  }

  final surfaceColorBackRoutes = {
    Routes.NOTIFICATIONS,
    Routes.PERMISSIONS,
    Routes.PRIVACY_POLICY,
    Routes.CONTACT_US,
    Routes.HELP_CENTER,
    Routes.PRIVACY_SECURITY,
    Routes.FORGOT_PASSWORD,
    Routes.DELETE_ACCOUNT,
  };

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
      if (surfaceColorBackRoutes.contains(route)) {
        if (route != Routes.FORGOT_PASSWORD) {
          final settingsAppBar = tester.widget<SettingsSliverAppBar>(
            find.byType(SettingsSliverAppBar),
          );
          expect(settingsAppBar.useSurfaceBackButtonColor, isTrue);
        }

        final appBar = tester.widget<AppScreenSliverAppBar>(
          find.byType(AppScreenSliverAppBar),
        );
        final backButton = appBar.leading! as CustomGlassButton;
        expect(backButton.glassColor, isNull);
        expect(
          backButton.foregroundColor,
          Theme.of(
            tester.element(find.byType(AppScreenSliverAppBar)),
          ).colorScheme.onSurface,
        );
        expect((backButton.child as Icon).icon, CupertinoIcons.back);
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
