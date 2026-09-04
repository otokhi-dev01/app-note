import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'package:Note/core/di/injector.dart';
import 'package:Note/core/localization/app_translations.dart';
import 'package:Note/core/storage/guest_mode_service.dart';
import 'package:Note/features/folder/presentation/controllers/folder_controller.dart';
import 'package:Note/features/folder/presentation/widgets/folder_tile.dart';
import 'package:Note/features/folder/presentation/widgets/folder_view_menu.dart';
import 'package:Note/routes/app_pages.dart';
import 'package:Note/shared/widgets/glass_widgets.dart';
import 'package:Note/shared/widgets/language_toggle_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => Directory.systemTemp.path,
        );
    await GetStorage.init();
    await LiquidGlassWidgets.initialize(enablePerformanceMonitor: false);
  });

  tearDown(() => Get.reset());

  testWidgets('folder header exposes search, notifications, menu, and edit', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await GetStorage().erase();
    InitialBinding().dependencies();
    Get.find<GuestModeService>().enable();

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
          initialRoute: Routes.FOLDER,
          getPages: AppPages.routes,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LanguageToggleButton), findsNothing);
    expect(find.bySemanticsLabel('Settings'), findsOneWidget);
    expect(find.bySemanticsLabel('Search notes and folders'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('folder-appbar-search-button')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Notifications'), findsOneWidget);
    expect(find.bySemanticsLabel('Folder view options'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);

    final appBar = tester.widget<AppScreenSliverAppBar>(
      find.byType(AppScreenSliverAppBar),
    );
    expect(appBar.actions, hasLength(3));
    expect(appBar.actions![2], isA<FolderViewMenu>());

    await tester.tap(find.bySemanticsLabel('Search notes and folders'));
    await tester.pumpAndSettle();
    expect(Get.currentRoute, Routes.SEARCH);

    Get.back();
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Notifications'));
    await tester.pumpAndSettle();
    expect(Get.currentRoute, Routes.NOTIFICATIONS);

    Get.back();
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Folder view options'));
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Short View'), findsOneWidget);
    expect(find.text('List View'), findsOneWidget);

    await tester.tap(find.text('Short View'));
    await tester.pumpAndSettle();
    expect(Get.find<FolderController>().viewMode.value, 'short');
    expect(GetStorage().read<String>('defaultFolderViewMode'), 'short');
    final shortTile = tester.widget<CustomGlassListTile>(
      find
          .descendant(
            of: find.byType(FolderTile),
            matching: find.byType(CustomGlassListTile),
          )
          .first,
    );
    expect(shortTile.subtitle, isNull);

    await tester.tap(find.bySemanticsLabel('Folder view options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('List View'));
    await tester.pumpAndSettle();
    expect(Get.find<FolderController>().viewMode.value, 'list');
    final listTile = tester.widget<CustomGlassListTile>(
      find
          .descendant(
            of: find.byType(FolderTile),
            matching: find.byType(CustomGlassListTile),
          )
          .first,
    );
    expect(listTile.subtitle, isNotNull);

    await tester.tap(find.bySemanticsLabel('Folder view options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(Get.find<FolderController>().isEditing.value, isTrue);

    await tester.tap(find.bySemanticsLabel('Folder view options'));
    await tester.pumpAndSettle();
    expect(find.text('Done'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(Get.find<FolderController>().isEditing.value, isFalse);
  });
}
