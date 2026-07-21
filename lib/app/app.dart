import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../feature/settings/presentation/controllers/settings_controller.dart';
import 'bindings/app_binding.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';
import 'translations/app_translation.dart';

class PiisiitNoteApp extends GetView<SettingsController> {
  const PiisiitNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => GetMaterialApp(
        title: 'Piisiit Note',
        debugShowCheckedModeBanner: false,
        initialBinding: AppBinding(),
        initialRoute: AppRoutes.splash,
        getPages: AppPages.pages,
        translations: AppTranslations(),
        locale: controller.currentLocale,
        fallbackLocale: const Locale('en', 'US'),
        themeMode: controller.themeMode,
        theme: AppTheme.light(fontFamily: controller.fontFamily),
        darkTheme: AppTheme.dark(fontFamily: controller.fontFamily),
      ),
    );
  }
}
