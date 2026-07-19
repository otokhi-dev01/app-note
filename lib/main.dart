import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'app/bindings/app_binding.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/theme/app_theme.dart';
import 'app/translations/app_translation.dart';
import 'feature/settings/presentation/controllers/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();

  Get.put<SettingsController>(
    SettingsController(),
    permanent: true,
  );

  runApp(PiisiitNoteApp(),
  );
}

class PiisiitNoteApp
    extends GetView<SettingsController> {
  const PiisiitNoteApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
          () => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Piisiit Note',
        initialRoute: AppRoutes.splash,
        getPages: AppPages.pages,
        initialBinding: AppBinding(),
        translations: AppTranslations(),
        locale: controller.currentLocale,
        fallbackLocale:
        Locale('en', 'US'),
        themeMode: controller.themeMode,
        theme: AppTheme.light(
          fontFamily: controller.fontFamily,
        ),
        darkTheme: AppTheme.dark(
          fontFamily: controller.fontFamily,
        ),
      ),
    );
  }
}